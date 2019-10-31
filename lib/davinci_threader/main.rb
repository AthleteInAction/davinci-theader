require 'colorize'
require 'awesome_print'
require 'active_support/core_ext/numeric/time'


module DavinciThreader
  class Main


    # Attributes
    # ======================================================
    def rpm=(value)
      @rpm = value
      self.max_threads = value*0.03
    end
    def rpm
      1.minute.to_f / @rpm.to_f
    end
    attr_accessor :log
    attr_accessor :log_errors
    attr_accessor :total
    attr_accessor :successful
    attr_accessor :errors
    attr_accessor :extras
    attr_accessor :max_threads
    attr_accessor :asynchronous
    def show_output=(_on)
      @show_output = _on
      if !_on
        @monitor.try(:exit)
        @monitor = nil
      end
    end
    def show_output
      @show_output
    end
    attr_accessor :synchronous_items
    attr_accessor :synchronous_completed
    attr_reader :thread_count
    # ======================================================

    # Initialize
    # ======================================================
    def initialize

      self.log = true
      self.log_errors = true
      self.rpm = 60
      self.total = 0
      self.successful = 0
      self.errors = 0
      self.extras = []
      self.max_threads = 10
      self.asynchronous = true
      self.show_output = true
      self.synchronous_items = []
      self.synchronous_completed = 0
      @threads = []
      @thread_count = 0

      @monitor = Thread.new do
        while self.log
          printout if self.show_output && @start_time
          sleep 0.1
        end
      end

      yield(self)

      @threads.each(&:join)
      @threads_finished_at = Time.now
      @monitor.try(:exit)
      if self.show_output && @synchronous
        self.printout
        print "\n"
      end
      @synchronous.try(:join)
      @synchronous.try(:exit)
      puts "\n-> Done!".light_green if self.show_output && self.log

    rescue Interrupt

      @monitor.try(:exit)

      begin
        puts "\n-> Waiting for remaining threads to finish...".yellow
        @threads.each(&:join)
        @synchronous.try(:exit)
        puts "-> Exited!".yellow
      rescue Interrupt
        force_exit
      end

      exit

    end
    # ======================================================

    # Synchronous Action
    # ======================================================
    def synchronous_action
      @synchronous = Thread.new do
        begin
          while !@threads_finished_at || self.synchronous_items.count > 0
            if self.synchronous_items.count == 0
              sleep(1)
            else
              yield(self.synchronous_items.first)
              self.synchronous_items.shift
              self.synchronous_completed += 1
              self.synchronous_printout if self.show_output && @threads_finished_at
            end
          end
        rescue => e
          ap e.message
          ap e.backtrace
        end
      end
    end
    # ======================================================

    # Make Thread
    # ======================================================
    def make_thread *args

      @start_time ||= Time.now

      if !self.asynchronous
        yield(*args)
        self.printout if self.show_output
        return
      end

      @threads << Thread.new(*args) do
        begin
          @thread_count += 1
          yield(*args)
          @thread_count -= 1
        rescue => e
          @thread_count -= 1
          self.errors += 1
          if self.log_errors
            output = [e.message.light_red]
            output += e.backtrace.map(&:yellow)
            print "\n#{output.join("\n")}\n"
          end
        end
      end

      sleep self.rpm
      sleep 0.1 while self.thread_count > self.max_threads

      @threads.each_with_index do |t,i|
        if !t.alive?
          t.exit
          @threads.delete_at(i)
        end
      end

    end
    # ======================================================

    # Printout
    # ======================================================
    def printout

        c = (@threads_finished_at || Time.now) - @start_time
        output = []
        if self.asynchronous
          output << "#{"#{@rpm.to_i}/MIN".cyan}"
          output << "#{Time.at(c.to_f).utc.strftime("%H:%M:%S")}"
          if self.completed > 100
            actual_rate = (self.completed.to_f / c.to_f) * 60.0
            output << "#{'%.2f' % actual_rate}/MIN".light_green
            output << "#{Time.at(((self.total-self.completed).to_f / actual_rate) * 60.0).utc.strftime("%H:%M:%S")}".light_green
          end
        end
        output << "#{self.completed}/#{self.total} (#{self.successful.to_s.light_green} <--> #{self.errors.to_s.light_red})"
        output << "Synchronous: #{"#{self.synchronous_items.count}".purple}" if @synchronous
        output += self.extras
        print "\r#{output.join(" :: ".yellow)}    "

      end
    # ======================================================

    # Synchronous Printout
    # ======================================================
    def synchronous_printout
      elapsed_time = Time.now - @threads_finished_at
      @synchronous_remaining = self.synchronous_items.count
      @synchronous_start_count ||= @synchronous_remaining
      @synchronous_completed_after_start = @synchronous_start_count - @synchronous_remaining
      if @synchronous_completed_after_start > 0
        @synchronous_rate_per_second = @synchronous_completed_after_start.to_f / elapsed_time
        seconds_remaining = @synchronous_remaining.to_f / @synchronous_rate_per_second
        @synchronous_nice_time = Time.at(seconds_remaining).utc.strftime("%H:%M:%S")
      end
      print "\r#{"Synchronous".purple} -> Remaining: #{"#{@synchronous_remaining}".light_yellow} :: Completed: #{"#{self.synchronous_completed}".light_green} :: Rate: #{"#{'%.2f' % ((@synchronous_rate_per_second || 0) * 60.0)}".light_cyan} :: #{"#{@synchronous_nice_time}".light_green}  "
    end
    # ======================================================

    # Increment Methods
    # ======================================================
    def success
      self.successful += 1
    end
    def error
      self.errors += 1
    end
    def completed
      self.errors+self.successful
    end
    # ======================================================

    # Force Exit
    # ======================================================
    def force_exit
      @monitor.try(:exit)
      puts "\n-> Killing remaining threads...".light_red
      @threads.each(&:exit)
      @synchronous.try(:exit)
      puts "-> Forced Exit!".light_red
    end
    # ======================================================


  end
end
