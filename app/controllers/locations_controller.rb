require "net/http"
require "json"
require "ipaddr"

class LocationsController < ApplicationController
  skip_before_action :authenticate_user!, only: :hint
  def hint
    client_ip     = real_client_ip(request)
    ip_for_lookup = public_ip?(client_ip) ? client_ip : nil # nil => use server egress IP

    # 1) ipapi.co (no key needed for light use). If it fails or has no city, try ipwho.is.
    data = lookup_ipapi(ip_for_lookup) || lookup_ipwho(ip_for_lookup)

    if data
      render json: {
        city: data[:city],
        lat:  data[:lat],
        lng:  data[:lng],
        ip:   client_ip,
        looked_up: (ip_for_lookup || "server")
      }
    else
      render json: { city: nil, lat: nil, lng: nil, ip: client_ip, looked_up: (ip_for_lookup || "server") }, status: :bad_gateway
    end
  end

  private

  def lookup_ipapi(ip)
    url = URI(ip ? "https://ipapi.co/#{ip}/json/" : "https://ipapi.co/json/")
    res = http_get(url)
    return nil unless res.is_a?(Net::HTTPSuccess)
    j = JSON.parse(res.body) rescue {}
    city = j["city"]
    lat  = j["latitude"]
    lng  = j["longitude"]
    return nil if city.blank?
    { city: city, lat: lat.to_f, lng: lng.to_f }
  rescue
    nil
  end

  def lookup_ipwho(ip)
    url = URI(ip ? "https://ipwho.is/#{ip}" : "https://ipwho.is/")
    res = http_get(url)
    return nil unless res.is_a?(Net::HTTPSuccess)
    j = JSON.parse(res.body) rescue {}
    return nil if j["success"] == false
    city = j["city"]
    lat  = j["latitude"]
    lng  = j["longitude"]
    return nil if city.blank?
    { city: city, lat: lat.to_f, lng: lng.to_f }
  rescue
    nil
  end

  def http_get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                    open_timeout: 1.5, read_timeout: 1.5) { |http| http.get(uri.request_uri) }
  end

  # Prefer real public IP from common proxy/CDN headers; fall back to XFF/remote_ip
  def real_client_ip(request)
    %w[CF-Connecting-IP True-Client-IP X-Real-IP X-Forwarded-For].each do |h|
      raw = request.headers[h]
      next if raw.blank?
      ip = (h == "X-Forwarded-For") ? raw.split(",").first&.strip : raw
      return ip if ip.present?
    end
    request.remote_ip
  end

  def public_ip?(ip)
    addr = IPAddr.new(ip) rescue nil
    return false if addr.nil?
    !(addr.loopback? || addr.private?)
  end
end
