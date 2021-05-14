defmodule Identicon do
  def main(input) do
    # the first item 'input' will be sent down to the
    # next functions
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  def save_image(image, input) do
    # string interpolation
    File.write("#{input}.png", image)
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    # iterate over every element.
    # .each is really only for transforming data, not returning it.
    Enum.each pixel_map, fn({start, stop}) ->
      # note: this is rare case when we are not transforming and
      # returning a new one, we are just modifying the exiting one in place.
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
      horizontal = rem(index, 5) * 50
      vertical = div(index, 5) * 50
      top_left ={horizontal, vertical}
      bottom_right = {horizontal + 50, vertical + 50}

      {top_left, bottom_right}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _index}) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{image | grid: grid}
  end

  # manipulate list into grid like structure
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index # used to know the index in the list.

    %Identicon.Image{image | grid: grid}
  end

  # helper function
  def mirror_row(row) do
    [first, second | _tail] = row
    row ++ [second, first]
  end

  def pick_color(%Identicon.Image{hex: [r ,g, b | _tail]} = image) do
    %Identicon.Image{image | color: {r, g, b}}
  end

  def hash_input(input) do
    # md5 is numbers that represent hexidecimal values.
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list # base identicon with this list of numbers.

    # create struct
    %Identicon.Image{hex: hex}
  end
end
