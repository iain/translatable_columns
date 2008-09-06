require File.dirname(__FILE__) + '/spec_helper'
require File.dirname(__FILE__) + '/cases/topic'

describe TranslatableColumns do

  before :each do
    @languages = %w{en nl de fr}
    @columns = @languages.map{|l|"title_#{l}"}
    @topic = Topic.new
    Topic.stub!(:find).and_return(@topic)

    # return these persistent values to their defaults
    ActiveRecord::Base.translatable_columns_config.set_defaults
    I18n.locale = 'nl-NL'
    I18n.default_locale = 'en-US'
  end

  it "should have a mocked model" do
    Topic.column_names.should include("title_en")
  end

  it "should find all localized columns" do
    Topic.available_translatable_columns_of(:title).should include(*@columns)
  end

  it "should get the language of a locale" do
    Topic.column_locale('nl-BE').should == 'nl'
  end

  it "should change nl-BE to nl_be because of database usage" do
    ActiveRecord::Base.translatable_columns_config.full_locale = true
    Topic.column_locale('nl-BE').should == 'nl_be'
  end

  it "should return a localized column" do
    Topic.column_name_localized('title', 'nl-NL').should == 'title_nl'
  end

  it "should check for existence of localized columns" do
    Topic.translated_column_exists?('title', 'nl-NL').should be_true
    Topic.translated_column_exists?('title', 'jp-JP').should be_false
  end

  it "should find the default column when asking for a non existing locale" do
    Topic.column_translated('title', 'jp-JP').should == 'title_en'
  end

  it "should find the column when asking for an existing locale" do
    Topic.column_translated('title', 'nl-NL').should == 'title_nl'
  end

  it "should define an accessor" do
    @topic.should respond_to(:title=)
    @topic.should respond_to(:title)
    @topic.should respond_to(:body=)
    @topic.should respond_to(:body)
  end

  it "should define a reader using defaults" do
    Topic.should_receive(:define_translated_getter_with_defaults)
    Topic.translatable_columns(:title)
  end

  it "should define a reader without using defaults" do
    Topic.should_receive(:define_translated_getter_without_defaults)
    Topic.translatable_columns(:title, :use_default => false)
  end

  it "should define a reader without using defaults, because of config" do
    ActiveRecord::Base.translatable_columns_config.use_default = false
    Topic.should_receive(:define_translated_getter_without_defaults)
    Topic.translatable_columns(:title)
  end

  it "should define a reader with defaults, inspite of config" do
    ActiveRecord::Base.translatable_columns_config.use_default = false
    Topic.should_receive(:define_translated_getter_with_defaults)
    Topic.translatable_columns(:title, :use_default => true)
  end

  it "should find a value in any column" do
    @columns.each do |column|
      @topic.send(:"#{column}=", column)
      @topic.find_translated_value_for(:title).should == column
      @topic = Topic.new # reset
    end
  end

  it "should retrieve the translated value, not using defaults" do
    Topic.translatable_columns :title, :use_default => false
    @topic.should_receive(:title_nl).and_return("foo")
    @topic.title.should == "foo"
  end

  it "should retrieve the translated value, using defaults" do
    Topic.translatable_columns :title, :use_default => true
    @topic.should_receive(:title_nl).and_return("foo")
    @topic.title.should == "foo"
  end

  it "should retrieve the default translation value when the locale doesn't exist, using no defaults" do
    I18n.locale = 'jp-JP'
    Topic.translatable_columns :title, :use_default => false
    @topic.should_receive(:title_en).and_return("foo")
    @topic.title.should == 'foo'
  end

  it "should retrieve the default translation value when the locale doesn't exist, when using defaults" do
    I18n.locale = 'jp-JP'
    Topic.translatable_columns :title, :use_default => true
    @topic.should_receive(:title_en).and_return("foo")
    @topic.title.should == "foo"
  end

  it "should find any value when using defaults" do
    @topic.should_receive(:title_fr).at_least(:once).and_return("foo")
    @topic.title.should == "foo"
  end

  it "should set a value for the current locale" do
    @topic.should_receive(:title_nl=)
    @topic.title = "foo"
  end

  it "should return a value for the default locale" do
    I18n.locale = 'jp-JP'
    @topic.should_receive(:title_en=)
    @topic.title = "foo"
  end

  it "should validate at least one translation" do
    @topic.valid?.should be_false
    @topic.should have(1).error_on(:title)
    @topic.should have(1).error_on(:body)
  end

  it "should have a :must_have_translation error message" do
    options = [:blank, { :default => :must_have_translation }]
    @topic.errors.should_receive(:add).with(:title, *options)
    @topic.errors.should_receive(:add).with(:body, *options)
    @topic.valid?
  end

end
