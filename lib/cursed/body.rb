class Cursed::Body < Cursed::Window

  def defaults
    { title: :body, border: false, exclusive: true, top: parent.header.top + parent.header.height, height: effective_height - parent.header.height }
  end

end
