module Madmin
  class ResourceController < Madmin::ApplicationController
    include SortHelper

    before_action :set_record, except: [:index, :new, :create]
    before_action :enforce_readonly, only: [:new, :create, :edit, :update, :destroy]

    # Assign current_user for paper_trail gem
    before_action :set_paper_trail_whodunnit, if: -> { respond_to?(:set_paper_trail_whodunnit, true) }

    def index
      @pagy, @records = paginate_collection(scoped_resources)

      respond_to do |format|
        format.html
        format.json {
          render json: @records.map { |r| {name: @resource.display_name(r), id: r.id} }
        }
      end
    end

    def show
    end

    def new
      @record = resource.model.new(new_resource_params)
    end

    def create
      @record = resource.model.new(resource_params)
      if @record.save
        redirect_to resource.show_path(@record)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @record.update(resource_params)
        redirect_to resource.show_path(@record)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @record.destroy
      redirect_to resource.index_path
    end

    private

    def set_record
      @record = resource.model_find(params[:id])
    end

    def resource
      @resource ||= resource_name.constantize
    end
    helper_method :resource

    def resource_name
      "#{controller_path.singularize}_resource".delete_prefix("madmin/").classify
    end

    def scoped_resources
      resources = resource.model.send(valid_scope)
      resources = Madmin::Search.new(resources, resource, search_term).run

      return resources if sort_column.blank?

      return sort_array(resources, sort_column, sort_direction) if Madmin.active_hash_model?(resource.model)

      resources.reorder(sort_column => sort_direction)
    end

    def valid_scope
      scope = params.fetch(:scope, "all")
      resource.scopes.include?(scope.to_sym) ? scope : :all
    end

    def resource_params
      params.require(resource.param_key)
        .permit(*resource.permitted_params)
        .transform_values { |v| change_polymorphic(v) }
    end

    def new_resource_params
      params.fetch(resource.param_key, {}).permit!
        .permit(*resource.permitted_params)
        .transform_values { |v| change_polymorphic(v) }
    end

    def change_polymorphic(data)
      return data unless data.is_a?(ActionController::Parameters) && data[:type]

      if data[:type] == "polymorphic"
        GlobalID::Locator.locate(data[:value])
      else
        raise "Unrecognised param data: #{data.inspect}"
      end
    end

    def search_term
      @search_term ||= params[:q].to_s.strip
    end

    def enforce_readonly
      redirect_to resource.index_path, alert: "#{resource.friendly_name} is read-only" if resource.readonly?
    end

    def paginate_collection(collection)
      return paginate_array(collection) if Madmin.active_hash_model?(resource.model)

      pagy(collection)
    end

    def paginate_array(collection)
      array = collection.to_a
      page = [params[:page].to_i, 1].max
      defaults = Pagy::DEFAULT || {}
      limit = (params[:limit] || defaults[:limit] || defaults[:items] || 20).to_i
      pagy_class = defined?(Pagy::Offset) ? Pagy::Offset : Pagy
      pager = begin
        pagy_class.new(count: array.size, page: page, limit: limit)
      rescue ArgumentError
        pagy_class.new(count: array.size, page: page, items: limit)
      end
      [pager, array.slice(pager.offset, pager.limit) || []]
    end

    def sort_array(collection, column, direction)
      array = collection.to_a.sort_by { |r| [(r.respond_to?(column) && !r.public_send(column).nil?) ? 0 : 1, r.public_send(column).to_s] }
      (direction.to_s == "desc") ? array.reverse : array
    end
  end
end
