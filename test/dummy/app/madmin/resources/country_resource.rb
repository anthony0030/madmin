class CountryResource < Madmin::Resource
  if defined?(ActiveHash::Base)
    attribute :id, form: false
    attribute :name
    attribute :code
  else
    menu false
  end
end
