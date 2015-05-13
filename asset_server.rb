require_relative "./asset_line"

class AssetsServer < Sinatra::Base
  def assets
    root_path = File.join(__dir__, "assets")
    AssetLine.new root: root_path
  end

  get /^\/assets\/\w+\/(?<filename>.+)$/ do
    if params["filename"].match /\.js$/
      content_type "application/javascript"
    elsif params["filename"].match /\.css$/
      content_type "text/css"
    end

    assets.fetch params.fetch("filename")
  end
end
