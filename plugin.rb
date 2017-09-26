# name: Watch Category
# about: Watches a category for all the users in a particular group
# version: 0.3
# authors: Arpit Jalan
# url: https://github.com/discourse/discourse-watch-category-mcneel

module ::WatchCategory

  def self.watch_category!
    groups_cats = {
      # "group" => ["category", "another-top-level-category", ["parent-category", "sub-category"] ],
      "Circle1" => [ "circle1", ["circle1", "indonesia-support"] ],
      "Circle2" => [ "circle2", ["circle2", "europe-support"] ],
      "Circle3" => [ "circle3", ["circle3", "india-support" ] ],
      "Circle4" => [ "circle4", ["circle4", "brazil-support"], ["circle4", "usa-canada-support"] ],

      "Brazil" => [ ["circle4", "brazil-support"] ],
      "Europe" => [ ["circle2", "europe-support"] ],
      "Indonesia" => [ ["circle1", "indonesia-support"] ],
      "USA" => [ ["circle4", "usa-canada-support"] ],
      "India" => [ ["circle3", "india-support"] ],
      
      "BrazilSales" => [ ["sales", "brazil-sales"] ],
      "EuropeSales" => [ ["sales", "europe-sales"] ],
      "USASales" => [ ["sales", "usa-canada-sales"] ]

      # "everyone" makes every user watch the listed categories
      # "everyone" => [ "announcements" ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching)

    groups_cats = {
      "CSD" => [ ["sales", "options"], ["sales", "tech"] ],
      "Regional" => [ [ "sales", "marketing" ], ["sales", "options"], ["sales", "tech"] ],
      "SalesAdmin" => [ [ "sales", "prices" ], ["sales", "options"], ["sales", "tech"] ],
      "OSD" => [ [ "sales", "prices" ], ["sales", "marketing" ], ["sales", "options"], ["sales", "tech"] ],
      "Management" => [ [ "sales", "prices" ], ["sales", "marketing" ], ["sales", "options"], ["sales", "tech"] ],
      "Tech" => [ ["sales", "options"], ["sales", "tech"] ],
      "everyone" => [ "test" ]
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching_first_post)
  end

  def self.change_notification_pref_for_group(groups_cats, pref)
    groups_cats.each do |group_name, cats|
      cats.each do |cat_slug|

        # If a category is an array, the first value is treated as the top-level category and the second as the sub-category
        if cat_slug.respond_to?(:each)
          category = Category.find_by_slug(cat_slug[1], cat_slug[0])
        else
          category = Category.find_by_slug(cat_slug)
        end
        group = Group.find_by_name(group_name)

        unless category.nil? || group.nil?
          if group_name == "everyone"
            User.all.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          else
            group.users.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          end
        end

      end
    end
  end

end

after_initialize do
  module ::WatchCategory
    class WatchCategoryJob < ::Jobs::Scheduled
      every 6.hours

      def execute(args)
        WatchCategory.watch_category!
      end
    end
  end
end
