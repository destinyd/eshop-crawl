class WineMonitor
  include Mongoid::Document
  include Mongoid::Timestamps
  field :lib, type: String
  field :sn, type: String
  field :min_price, type: Money
  field :current_price, type: Money
  field :price_per_liter, type: Money
  field :min_price_per_liter, type: Money
  field :name, type: String
  field :en_name, type: String
  field :description, type: String
  field :norm, type: Integer
  field :finished_at, type: DateTime
  belongs_to :website
  has_many :wine_prices
  has_and_belongs_to_many :wines

  scope :recent, desc(:created_at)
  scope :cheapest, asc(:current_price)
  scope :running, where(:finished_at => nil)
  scope :cheapest_per_liter, asc(:price_per_liter)

  validates :wines, presence: true

  after_update :set_price_per_liter, :set_wine_price
  after_create :set_price_per_liter, :set_lib,:init_from_page

  def to_s
    name
  end

  def set_wine_price
    wines.each do |wine|
      if min_price.nil? or min_price == 0 or (current_price < min_price)
        update_attribute :min_price, current_price
      end

      if wine.min_price.nil? or wine.min_price == 0 or (current_price < wine.min_price)
        wine.update_attribute :min_price, current_price
      end

      wine.update_attribute :current_price, wine.wine_monitors.cheapest.first.try(:current_price)
    end
  end

  def url
    @url ||= lib.capitalize.constantize.new(id: sn).url
  end

  def finish
    update_attribute :finished_at, Time.now if finished_at.nil?
  end

  def set_price_per_liter
    if current_price and  norm and norm > 0
      tmp_price_per_liter = (current_price / norm.to_f * 1000).to_money

      update_attribute :price_per_liter, tmp_price_per_liter if tmp_price_per_liter != price_per_liter
      update_attribute :min_price_per_liter, tmp_price_per_liter if min_price_per_liter.nil? or tmp_price_per_liter < min_price_per_liter
      set_wine_price_per_liter
    end
  end

  def set_wine_price_per_liter
    wines.each do |wine|
      if wine.min_price_per_liter.nil? or wine.min_price_per_liter == 0 or min_price_per_liter < wine.min_price_per_liter
        wine.update_attribute :min_price_per_liter, min_price_per_liter
      end
      wine.update_attribute :price_per_liter, wine.wine_monitors.cheapest_per_liter.first.try(:price_per_liter)
    end
  end

  def set_lib
    update_attribute :lib, website.lib
  end

  def init_from_page
    (lib.capitalize + "Crawler").constantize.new.init_from_page(self)
  end
end
