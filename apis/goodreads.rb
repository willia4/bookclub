require 'net/http'
require 'nokogiri'

module APIs
  module Goodreads
    def self.make_xml_api_call(endpoint, parameters = {})
      parameters["key"] = $config[:goodreads][:api_key]

      u = URI.join("https://www.goodreads.com", endpoint)
      u.query = URI.encode_www_form(parameters)

      http = Net::HTTP.new(u.host, u.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(u.request_uri)
      response = http.request(request)

      if response.code != "200"
        #todo
        raise "Oh No"
      end
      body = response.body 
      doc = Nokogiri::XML(body)

      return doc
    end

    def self.lookup_book(id)
      parameters = {"id" => id.to_s}
      data = make_xml_api_call("/book/show.xml", parameters)
      book = data.at_xpath("/GoodreadsResponse/book")
      return nil if book.nil? 

      title = book.at_xpath("title")
      title = title.nil? ? "" : title.text

      author = book.at_xpath("authors/author/name")
      author = author.nil? ? "" : author.text

      url = book.at_xpath("url")
      url = url.nil? ? "" : url.text

      image = book.at_xpath("image_url")
      image = image.nil? ? "" : image.text

      image_thumbnail = book.at_xpath("small_image_url")
      image_thumbnail = image_thumbnail.nil? ? "" : image_thumbnail.text

      description = book.at_xpath("description")
      description = description.nil? ? "" : description.text

      return { :id => id, :title => title, :author => author, :url => url, :image => image, :image_thumbnail => image_thumbnail, :description => description }
    end

    def self.search(query_string)
      one = {:id => "9844623", :title => "Feynman", :author => "Jim Ottaviani", :image => "https://d.gr-assets.com/books/1317793632m/9844623.jpg", :image_thumbnail => "https://d.gr-assets.com/books/1317793632s/9844623.jpg"}
      two = {:id => "223458", :title => "Feynman Lectures on Gravitation", :author => "Richard P. Feynman", :image => "https://s.gr-assets.com/assets/nophoto/book/111x148-c93ac9cca649f584bf7c2539d88327a8.png", :image_thumbnail => "https://s.gr-assets.com/assets/nophoto/book/50x75-4845f44723bc5d3a9ac322f99b110b1d.png"}

      results = []
      30.times do 
        results << one
        results << two
      end

      return results
      # total_page_count = 3
      # works = []

      # (1..total_page_count).each do |page_number|
      #   parameters = { "q" => query_string, "page" => page_number}
      #   data = make_xml_api_call("/search/index.html", parameters)

      #   works.concat(data.xpath("//search/results/work") || [])

      #   results_end = data.at_xpath("//search/results-end").text.to_i
      #   total_results = data.at_xpath("//search/total-results").text.to_i

      #   break unless total_results > results_end #stop paging if we have enough pages
      # end

      # results = []
      # works.each do |work|
      #   best_book = work.at_xpath("//best_book")
      #   next if best_book.nil?

      #   id = best_book.at_xpath("id")
      #   id = id.nil? ? "" : id.text 

      #   title = best_book.at_xpath("title")
      #   title = title.nil? ? "" : title.text
 
      #   author = best_book.at_xpath("author/name")
      #   author = author.nil? ? "" : author.text

      #   image = best_book.at_xpath("image_url")
      #   image = image.nil? ? "" : image.text

      #   image_thumbnail = best_book.at_xpath("small_image_url")
      #   image_thumbnail = image_thumbnail.nil? ? "" : image_thumbnail.text 

      #   next if id.nil? || id.empty? || title.nil? || title.empty? 

      #   results << { :id => id, :title => title, :author => author, :image => image, :image_thumbnail => image_thumbnail }
      # end

      # return results
    end
  end
end