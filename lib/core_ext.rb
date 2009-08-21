class Array
  
  def map_with_index!
    each_with_index do |e, idx| self[idx] = yield(e, idx); end
  end
  
  def map_with_index(&block)
    dup.map_with_index!(&block)
  end
  
  def grep_indexes r
    map{|v| v.to_s =~ r ? index(v) : nil }.compact
  end

  def grep_index r
    index detect{|v| v.to_s =~ r }
  end

  def grep_start_stop start, stop
    if start_pos = grep_index(start)
      if stop_pos = slice(start_pos+1..-1).grep_index(stop)
        [start_pos, stop_pos+start_pos+1]
      end
    end
  end

  def rslice start, stop
    if ss = grep_start_stop(start,stop)
      slice(ss.first..ss.last)
    end
  end
  
end

class Object
  module InstanceExecHelper; end
  include InstanceExecHelper
  def instance_exec(*args, &block)
    begin
      old_critical, Thread.critical = Thread.critical, true
      n = 0
      n += 1 while respond_to?(mname="__instance_exec#{n}")
      InstanceExecHelper.module_eval{ define_method(mname, &block) }
    ensure
      Thread.critical = old_critical
    end
    begin
      ret = send(mname, *args)
    ensure
      InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
    end
    ret
  end
end