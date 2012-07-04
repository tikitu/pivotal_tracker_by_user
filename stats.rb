#!/usr/bin/ruby

require 'rubygems'
require 'fastercsv'
require 'active_support/core_ext'
require 'time'
require 'date'
Dir['models/*.rb'].each { |file| require file }

unless [1,3].include?(ARGV.length)
  puts "Usage: #{__FILE__} [--from YYYY/MM/DD] <Your CSV file>"
  exit
end

if ARGV.length == 3
  # Is this really necessary?! Ripped from http://stackoverflow.com/questions/800118/ruby-time-parse-gives-me-out-of-range-error
  from_date = Date._strptime(ARGV[1], "%Y/%m/%d")
  from_date = Time.utc(from_date[:year], from_date[:mon], from_date[:mday])
  # print "Parsed ", from_date, " from ", ARGV[1], "\n"
end

features, bugs, chores, dates = [], [], [], []

FasterCSV.foreach(ARGV.last, :headers => true) do |row|
  unless (date = row["Accepted at"]).nil?
    iteration_date = Time.parse(row["Iteration End"])
    if from_date and iteration_date < from_date
      next
    end
    user = row["Owned By"].nil? ? "Unassigned" : row["Owned By"]
    case row['Story Type']
      when 'feature' then features << Feature.new(user, row["Estimate"].to_i, date, row["Iteration"])
      when 'bug' then bugs << Bug.new(user, date, row["Iteration"])
      when 'chore' then chores << Chore.new(user, date, row["Iteration"])
    end
    dates << iteration_date
  end
end

iterations = Story.group_by_iteration(features)
output = Output.new(Story.users(features).max_by(&:length))
dates = dates.uniq!.sort

output.number_of_iterations(iterations, dates)
output.global_info(dates, Feature.sum_total(features), Story.number_by_iteration(bugs), Story.number_by_iteration(chores))
output.features_info(dates, features, iterations)
output.bugs_info(dates, bugs, iterations)
output.chores_info(dates, chores, iterations)
