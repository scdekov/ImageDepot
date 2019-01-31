module Api
  class LinksController < ApplicationController
    def show
      path = Depot.get_img_path(show_link_params)
      !path.nil? ? send_file(path) : render(status: 404)
    end

    def create
      render json: { links: Depot.get_links(create_link_params) }
    end

    def create_link_params
      params.require(:term)
    end

    def show_link_params
      params.require(:id)
    end
  end
end
