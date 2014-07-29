class Cursed::Menu < Cursed::Container

  HEIGHT = 4

  def defaults
    { title: :menu, border: true, bc: :blue, fg: :yellow, top: parent.top + parent.height - HEIGHT, height: HEIGHT }
  end

end
