module Api
  class LinksController < ApplicationController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    TOKEN = Rails.application.credentials[:API_TOKEN]

    before_action :authorize, except: [:show]

    def show
      path = Depot.get_img_path(show_link_params)
      !path.nil? ? send_file(path) : render(status: 404)
    end

    def create
      render json: { links: Depot.get_links(create_link_params) }
    end

    private

    def authorize
      authenticate_or_request_with_http_token do |token, _|
        ActiveSupport::SecurityUtils.secure_compare(token, TOKEN)
      end
    end

    def create_link_params
      params.require(:term)
    end

    def show_link_params
      params.require(:id)
    end
  end
end
