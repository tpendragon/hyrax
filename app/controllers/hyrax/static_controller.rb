module Hyrax
  class StaticController < ApplicationController
    layout 'homepage'

    def zotero
      respond_to do |format|
        format.html
        format.js { render layout: false }
      end
    end

    def mendeley
      respond_to do |format|
        format.html
        format.js { render layout: false }
      end
    end
  end
end
