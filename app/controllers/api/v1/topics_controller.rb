module Api
  module V1
    class TopicsController < ApiController
      api :GET, '/topics', 'Fetch category, subcategory, indicators list'
      formats ['json']
      description <<-EOS
        == Fetch category, subcategory, indicators
      EOS

      def index
        category_groups = CategoryGroup.with_sub_categories.select { |cg| cg.sub_categories.with_indicators.count > 0 }
        render json: category_groups
      end

      api :GET, '/topic_city/:year/:indicator_slug', 'Fetch detailed data of topic'
      param :year, String, :desc => 'year', :required => true
      param :indicator_slug, String, :desc => 'indicator slug', :required => true
      formats ['json']
      description <<-EOS
        == Fetch detailed data for indicatior and year in city area
        response data has detailed data for indicator and year
      EOS

      def city_show
       @data = Resource.includes(:demo_group, :uploader, :indicator, :number, :cum_number, :ave_annual_number, :crude_rate, :lower_95ci_crude_rate, :upper_95ci_crude_rate, :percent, :lower_95ci_percent, :upper_95ci_percent, :weight_number, :weight_percent, :lower_95ci_weight_percent, :upper_95ci_weight_percent).where("year_from <= ? AND year_to >= ?", params[:year], params[:year]).where(geo_group_id: GeoGroup.find_by_geography('City')).select { |resource| resource.indicator.slug == params[:indicator_slug] }
        render json: @data, each_serializer: TopicCitySerializer
        render json: @data, each_serializer: TopicCitySerializer
      end

      api :GET, '/topic_area/:year/:indicator_slug', 'Fetch detailed data of topic'
      param :year, String, :desc => 'year', :required => true
      param :indicator_slug, String, :desc => 'indicator id', :required => true
      formats ['json']
      description <<-EOS
        == Fetch detailed data for indicatior and year in city area
        response data has detailed data for indicator and year
      EOS

      def area_show
        @data = Resource.where("year_from <= ? AND year_to >= ?", params[:year], params[:year]).where(indicator_id: Indicator.find_by_slug(params[:indicator_slug])).where.not(geo_group_id: GeoGroup.find_by_geography('City'))
        render json: @data, each_serializer: TopicAreaSerializer
      end

      api :GET, '/topic_detail/:indicator_slug', 'Fetch detailed data of topic for trend'
      param :indicator_slug, String, :desc => 'indicator slug', :required => true
      formats ['json']
      description <<-EOS
        == Fetch detailed data for indicatior
        response data has detailed data for indicator(for trend all year data)
      EOS

      def trend
        @data         =   Resource.where(indicator_id: Indicator.find_by_slug(params[:indicator_slug]))
        @demo_list    = DemoGroup.select {|s| Resource.find_by(indicator_id: Indicator.find_by_slug(params[:indicator_slug]), demo_group_id: s) != nil}

        render json: {
          data: ActiveModel::Serializer::ArraySerializer.new(@data, serializer: TopicDetailSerializer),
          demo_list: ActiveModel::Serializer::ArraySerializer.new(@demo_list, serializer: DemoListSerializer)
        }
      end

      api :GET, '/topic_demo/:indicator_slug/:demo_slug', 'Fetch trend data regarding demography'
      param :indicator_slug, String, :desc => 'indicator_slug', :required => true
      param :demo_slug, String, :desc => 'demography slug', :required => true
      formats ['json']
      description <<-EOS
        == Fecth detailed data for demography
        response data has detailed data for demography(for trend all year data)
      EOS

      def demo
        @data = Resource.select { |d| (d.demo_group.demography.downcase == params[:demo_slug].downcase unless d.demo_group.blank?) && (d.indicator.slug == params[:indicator_slug]) }
        render json: @data, each_serializer: TopicDemoSerializer
      end

      api :GET, '/topic_recent/:indicator_slug', 'Fetch detailed data of topic'
      param :indicator_slug, String, :desc => 'indicator slug', :required => true
      formats ['json']
      description <<-EOS
        == Fetch detailed data for indicatior and year
        response data has detailed data for indicator and year
      EOS
      def recent
        # slug  = params[:indicator_slug]
        # index = Indicator.find_by(slug: slug)
         year  = Resource.where(indicator_id: index).maximum('year_to')
        @data = Resource.where("year_from <= ? AND year_to >= ?",year,year).where(indicator_id: Indicator.find_by(slug: params[:indicator_slug]))
        render json: @data
      end

      api :GET, '/topic_info/:geo_slug/:indicator_slug', 'Fetch detailed data of topic for community area'
      param :indicator_slug, String, :desc => 'indicator slug', :required => true
      param :geo_slug, String, :desc => 'geo_slug', :required => true
      formats ['json']
      description <<-EOS
        == Fetch detailed data for community area
      EOS
      def info
        # indicator_slug = params[:indicator_slug]
        # geo_slug       = params[:geo_slug]
        # geo_group_id   = GeoGroup.find_by_slug(params[:geo_slug])
        # indicator_id   = Indicator.find_by_slug(params[:indicator_slug])
        # chicago_id     = GeoGroup.find_by_slug('chicago')
        @area_data     = Resource.where(indicator_id: Indicator.find_by_slug(params[:indicator_slug]), geo_group_id: GeoGroup.find_by_slug(params[:geo_slug]))
        @city_data     = Resource.where(indicator_id: Indicator.find_by_slug(params[:indicator_slug]), geo_group_id: GeoGroup.find_by_slug('chicago'))

        render json: {
          :area_data => ActiveModel::Serializer::ArraySerializer.new(@area_data, serializer: TopicAreaInfoSerializer),
          :demo_list => ActiveModel::Serializer::ArraySerializer.new(@city_data, serializer: TopicCityInfoSerializer)
        }
      end
    end
  end
end
