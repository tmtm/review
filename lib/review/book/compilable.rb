#
# $Id: book.rb 4315 2009-09-02 04:15:24Z kmuto $
#
# Copyright (c) 2002-2008 Minero Aoki
#               2009 Minero Aoki, Kenshi Muto
#
# This program is free software.
# You can distribute or modify this program under the terms of
# the GNU LGPL, Lesser General Public License version 2.1.
# For details of the GNU LGPL, see the file "COPYING".
#
require 'review/textutils'
module ReVIEW
  module Book
    module Compilable
      include TextUtils
      attr_reader :book
      attr_reader :path

      def env
        @book
      end

      def dirname
        return nil unless @path
        File.dirname(@path)
      end

      def basename
        return nil unless @path
        File.basename(@path)
      end

      def name
        File.basename(@name, '.*')
      end

      alias id name

      def title
        @title = ""
        open {|f|
          f.each_line {|l|
            l = convert_inencoding(l, ReVIEW.book.param["inencoding"])
            if l =~ /\A=+/
              @title = l.sub(/\A=+/, '').strip
              break
            end
          }
        }
        @title
      end

      def size
        File.size(path())
      end

      def volume
        @volume ||= Volume.count_file(path())
      end

      def open(&block)
        return (block_given?() ? yield(@io) : @io) if @io
        File.open(path(), &block)
      end

      def content
        @content = convert_inencoding(File.read(path()),
                                      ReVIEW.book.param["inencoding"])
      end

      def lines
        # FIXME: we cannot duplicate Enumerator on ruby 1.9 HEAD
        (@lines ||= content().lines.to_a).dup
      end

      def list(id)
        list_index()[id]
      end

      def list_index
        @list_index ||= ListIndex.parse(lines())
        @list_index
      end

      def table(id)
        table_index()[id]
      end

      def table_index
        @table_index ||= TableIndex.parse(lines())
        @table_index
      end

      def footnote(id)
        footnote_index()[id]
      end

      def footnote_index
        @footnote_index ||= FootnoteIndex.parse(lines())
        @footnote_index
      end

      def image(id)
        return image_index()[id] if image_index().has_key?(id)
        return icon_index()[id] if icon_index().has_key?(id)
        return numberless_image_index()[id] if numberless_image_index().has_key?(id)
        indepimage_index()[id]
      end

      def numberless_image_index
        @numberless_image_index ||=
          NumberlessImageIndex.parse(lines(), id(),
          "#{book.basedir}#{@book.image_dir}",
          @book.image_types)
      end

      def image_index
        @image_index ||= ImageIndex.parse(lines(), id(),
          "#{book.basedir}#{@book.image_dir}",
          @book.image_types)
        @image_index
      end

      def icon_index
        @icon_index ||= IconIndex.parse(lines(), id(),
          "#{book.basedir}#{@book.image_dir}",
          @book.image_types)
        @icon_index
      end

      def indepimage_index
        @indepimage_index ||=
          IndepImageIndex.parse(lines(), id(),
          "#{book.basedir}#{@book.image_dir}",
          @book.image_types)
      end

      def bibpaper(id)
        bibpaper_index()[id]
      end

      def bibpaper_index
        raise FileNotFound, "no such bib file: #{@book.bib_file}" unless @book.bib_exist?
        @bibpaper_index ||= BibpaperIndex.parse(@book.read_bib.lines.to_a)
        @bibpaper_index
      end

      def headline(caption)
        headline_index()[caption]
      end

      def headline_index
        @headline_index ||= HeadlineIndex.parse(lines(), self)
      end

      def headline_by_label(label)
        headline_index.by_label(label)
      end
    end
  end
end

