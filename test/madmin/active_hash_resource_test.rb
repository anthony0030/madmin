require "test_helper"

class ActiveHashResourceTest < ActiveSupport::TestCase
  def setup
    skip "active_hash not available" unless defined?(ActiveHash::Base)
  end

  test "detects active_hash models" do
    assert Madmin.active_hash_model?(Country)
    assert_not Madmin.active_hash_model?(User)
  end

  test "sortable_columns uses field names" do
    assert_equal %w[id name code], CountryResource.sortable_columns
  end

  test "infers string type for active_hash fields" do
    assert_equal :string, CountryResource.attributes[:name].type
    assert_equal :string, CountryResource.attributes[:code].type
  end

  test "searchable_attributes for active_hash string fields" do
    names = CountryResource.searchable_attributes.map(&:name)
    assert_includes names, :name
    assert_includes names, :code
  end

  test "search filters active_hash records" do
    relation = Madmin::Search.new(Country, CountryResource, "canada").run
    assert_equal ["Canada"], relation.map(&:name)
  end

  test "search returns all when query blank" do
    relation = Madmin::Search.new(Country, CountryResource, "").run
    assert_equal 3, relation.count
  end

  test "find works via model_find" do
    assert_equal "Canada", CountryResource.model_find(2).name
  end

  test "readonly? returns true for active_hash" do
    assert CountryResource.readonly?
    assert_not UserResource.readonly?
  end
end
