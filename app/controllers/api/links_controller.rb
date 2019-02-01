module Api
  class LinksController < ApplicationController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    TOKEN = Rails.application.credentials[:API_TOKEN]

    before_action :authorize, except: [:show]

    def show
      img = Depot.new(params[:term]).get_img(params[:identifier])
      !img.nil? ? send_data(img, filename: "#{params[:identifier]}.png") : render(status: 404)
    end

    def create
      depot = Depot.new(create_link_params[:term])
      render json: { spelling_correction: depot.spelling_correction,
                     links: depot.get_links(create_link_params[:count] || 5,
                                            create_link_params[:width] || 200,
                                            create_link_params[:height] || 200) }
    end

    private

    def authorize
      authenticate_or_request_with_http_token do |token, _|
        ActiveSupport::SecurityUtils.secure_compare(token, TOKEN)
      end
    end

    def create_link_params
      params.require(:term)
      params.permit(:term, :count, :width, :height)
    end
  end
end
