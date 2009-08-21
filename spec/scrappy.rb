require File.join(File.dirname(__FILE__), '..', 'lib', 'scrappy.rb')

class ScrappyTestParser
  
  include Scrappy::Mappable
  
  before do
    self.context = {}
  end
  
  match /About the .* file/, [//, /Robots\.txt Notes/] do |line|
    @context[:about] ||= []
    clean = line.strip
    @context[:about] << clean unless clean.empty?
  end
  
  match /About the .* file/, [//, /Robots\.txt Notes/] do |line|
    @context[:about2] = true
  end
  
  match /^Robots\.txt Notes/, /Examples of Robots\.txt Entries/ do |line|
    @context[:notes] ||= []
    clean = line.strip
    @context[:notes] << clean unless clean.empty?
  end
  
  match /^Disallow|^User-agent/ do |line,matches|
    @context[:rules] ||= []
    @context[:rules] << [matches, line]
  end
  
  match /^WARNING /, /^Robotcop/ do |line|
    match /^ {4,}/ do |line|
      @context[:warning] ||= []
      @context[:warning] << line
    end
  end
  
  match(/robot/i) do |line, m|
    @context[:robots] ||= []
    @context[:robots] += m.flatten
  end
  
end

PARSER = (
  stp = ScrappyTestParser.new
  file = File.join(File.dirname(__FILE__), 'test.txt')
  stp.parse File.read(file)
  stp
)

describe ScrappyTestParser do
  
  before do
    @parser = PARSER
  end
  
  it 'should be able to parse a range of lines' do
    @parser.context[:about].should include('About the Robots.txt file')
  end
  
  it 'should not parse the same line twice' do
    @parser.context.key?(:about2).should == false
  end
  
  context 'it should be able to parse the "notes"' do
    it 'should have 15 lines' do
      @parser.context[:notes].size.should == 15
    end
    it 'should have the correct first sentence' do
      expected = "Robots.txt Notes"
      @parser.context[:notes].first.should == expected
    end
    it 'should have the correct last sentence' do
      expected = "Examples of Robots.txt Entries"
      @parser.context[:notes].last.should == expected
    end
  end
  
end