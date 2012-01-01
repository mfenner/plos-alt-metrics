module PostsHelper
  def page_title
    if controller.action_name == "edit"
      "Edit"
    else
      "Tweets"
    end
  end
end
