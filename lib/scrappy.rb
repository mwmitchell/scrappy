require File.join(File.dirname(__FILE__), 'core_ext')

module Scrappy
  
  # builds and returns rules
  module Ruleable
    
    attr_accessor :context
    
    # propogate the context to each rule
    def context=(c)
      @context = c
      self.rules.each{|r|r.context ||= c}
    end
    
    def rules
      @rules ||= []
    end
    
    def match start, stop=[], &blk
      unless self.rules.any?{|r| r.blk.to_s == blk.to_s}
        self.rules << Rule.new(start, stop, self.context, &blk)
      end
    end
    
  end
  
  # parses text, sending each line through a hierarchy of rules
  module Parseable
    
    def parse text
      current = nil
      text = text.split(/\n/) unless text.is_a? Array
      text.each_with_index do |line,index|
        matches = []
        if current.nil? and rule = self.rules.detect{|r| matches = (r.start? text, index) }
          current = rule
        end
        if current
          current.execute text, index, matches
          current = nil if current.stop? text, index
        end
      end
    end
    
  end
  
  class Rule
    
    include Ruleable
    include Parseable
    
    attr :start
    attr :stop
    attr :blk
    
    attr :context
    
    def initialize start, stop, context, &blk
      start = [start] unless start.respond_to? :each
      stop = [stop] unless stop.respond_to? :each
      @start, @stop, @context, @blk = start, stop, context, blk
    end
    
    def start? text, index
      stop_start? :start, text, index
    end
    
    def stop? text, index
      return true if @stop.empty?
      stop_start? :stop, text, index
    end
    
    # The "if ! rules.any?" returns true the first time (always).
    # This causes the block to execute and (possibly) populate the rules array.
    # The "if" prevents parents from procesing lines that their children want to process.
    def execute text, index, matches
      line = text[index]
      case blk.arity
      when 1
        a = [line]
      when 2
        a = [line,matches]
      when 3
        a = [line,matches,index]
      end
      instance_exec *a, &self.blk if ! self.rules.any?{|r| r.start?(text, index) }
      parse line
    end
    
    protected
    
    # mode must be :stop or :start
    # runs through each of the stop/start rules
    # passing in lines (incremented) ahead to see if they all match or not.
    # returns false or the position of the match
    def stop_start?(mode, text, index)
      result = send(mode).map_with_index {|s,i| text[i+index].scan(s) }
      result.all?{|c|!c.all?{|cc|!cc.all?}} ? result : false
    end
    
  end
  
  module Mapper
    
    def self.included(b)
      b.extend Ruleable
      b.extend Events
    end
    
    module Events
      def events
        @events ||= {:before=>[],:after=>[]}
      end
      def before(&blk)
        events[:before] << blk
      end
      def after(&blk)
        events[:after] << blk
      end
    end
    
    include Parseable
    
    attr_accessor :context
    
    def initialize(context=nil)
      @context = context
      self.class.events[:before].each do |e|
        instance_eval &e
      end
      self.class.context = @context
    end
    
    def rules
      self.class.rules
    end
    
    def parse(*args,&blk)
      result = super
      self.class.events[:after].each do |e|
        instance_eval &e
      end
      result
    end
    
  end
  
end