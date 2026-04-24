if defined?(ActiveHash::Base)
  class Country < ActiveHash::Base
    fields :name, :code

    self.data = [
      {id: 1, name: "United States", code: "US"},
      {id: 2, name: "Canada", code: "CA"},
      {id: 3, name: "Mexico", code: "MX"}
    ]
  end
else
  class Country
  end
end
