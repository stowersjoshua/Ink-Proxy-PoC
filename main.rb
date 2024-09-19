puts 'STARTING!'

require 'prawn'
require 'prawn/measurement_extensions'
require_relative 'card'

# Ref: https://apidock.com/rails/Array/in_groups_of
class Array
  def in_groups_of(number, fill_with = nil)
    if fill_with == false
      collection = self
    else
      # size % number gives how many extra we have;
      # subtracting from number gives how many to add;
      # modulo number ensures we don't add group of just fill.
      padding = (number - size % number) % number
      collection = dup.concat([fill_with] * padding)
    end

    if block_given?
      collection.each_slice(number) { |slice| yield(slice) }
    else
      groups = []
      collection.each_slice(number) { |group| groups << group }
      groups
    end
  end
end

def fetch_card_images(cards)
  image_paths = []
  cards.each do |card_info|
    card = Card.fetch(set: card_info[:set], number: card_info[:number])
    image_paths << card.image_path if card.image_path
  end
  image_paths
end

def create_pdf_with_images(image_paths, output_file)
  card_width = 2.5.in * 0.96 # I used 0.95 last time and it was an itsy bitsy bit small
  card_height = 3.5.in * 0.96

  Prawn::Document.generate(output_file, margin: 0) do |pdf|
    page_width = pdf.bounds.width
    page_height = pdf.bounds.height

    cards_per_column = (page_width / card_width).floor
    cards_per_row = (page_height / card_height).floor

    spare_x = page_width - (cards_per_column * card_width)
    padding_x = spare_x / (cards_per_column + 1).floor

    spare_y = page_height - (cards_per_row * card_height)
    padding_y = spare_y / (cards_per_row + 1).floor

    cards_per_page = cards_per_column * cards_per_row

    calc_col = -> (i) { i % cards_per_column }
    calc_row = -> (i) { (i / cards_per_column).floor }

    calc_x = -> (col) { (col * card_width) + (col.next * padding_x) }
    calc_y = -> (row) { page_height - (row * card_height) - (row.next * padding_y) }

    image_paths.in_groups_of(cards_per_page) do |paths|
      paths.each_with_index do |path, index|
        next if path.nil?

        x = calc_x.call(calc_col.call(index))
        y = calc_y.call(calc_row.call(index))

        pdf.image path, width: card_width, height: card_height, at: [x, y]

        next if image_paths.last == path
        pdf.start_new_page if index.next % cards_per_page == 0
      end
    end
  end
end

cards = [
  { set: 1, number: 195 },
  { set: 1, number: 195 },
  { set: 1, number: 195 },

  { set: 2, number: 176 },
  { set: 2, number: 176 },
  { set: 2, number: 183 },
  { set: 2, number: 184 },

  { set: 3, number: 36 },
  { set: 3, number: 36 },
  { set: 3, number: 36 },
  { set: 3, number: 36 },
  { set: 3, number: 38 },
  { set: 3, number: 38 },
  { set: 3, number: 42 },
  { set: 3, number: 42 },
  { set: 3, number: 42 },
  { set: 3, number: 42 },
  { set: 3, number: 51 },
  { set: 3, number: 51 },
  { set: 3, number: 51 },
  { set: 3, number: 51 },
  { set: 3, number: 191 },
  { set: 3, number: 191 },
  { set: 3, number: 191 },

  { set: 5, number: 49 },
  { set: 5, number: 49 },
  { set: 5, number: 172 },
]

output_file = 'proxies.pdf'

image_paths = fetch_card_images(cards)
create_pdf_with_images(image_paths, output_file)

puts "PDF created successfully: #{output_file}"
