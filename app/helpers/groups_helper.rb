module GroupsHelper
  def can_change_group_visibility_level?(group)
    can?(current_user, :change_visibility_level, group)
  end

  def group_icon(group)
    if group.is_a?(String)
      group = Group.find_by_full_path(group)
    end

    group.try(:avatar_url) || ActionController::Base.helpers.image_path('no_group_avatar.png')
  end

  def group_title(group, name = nil, url = nil)
    @has_group_title = true
    full_title = ''

    group.ancestors.reverse.each_with_index do |parent, index|
      if show_new_nav? && index > 0
        add_to_breadcrumb_dropdown(group_title_link(parent, hidable: false, show_avatar: true), location: :before)
      else
        full_title += if show_new_nav?
                        breadcrumb_list_item group_title_link(parent, hidable: false)
                      else
                        "#{group_title_link(parent, hidable: true)} <span class='hidable'> / </span>".html_safe
                      end
      end
    end

    if show_new_nav?
      full_title += render "layouts/nav/breadcrumbs/collapsed_dropdown", location: :before, title: _("Show parent subgroups")
    end

    full_title += if show_new_nav?
                    breadcrumb_list_item group_title_link(group)
                  else
                    group_title_link(group)
                  end
    full_title += ' &middot; '.html_safe + link_to(simple_sanitize(name), url, class: 'group-path breadcrumb-item-text js-breadcrumb-item-text') if name

    if show_new_nav?
      full_title.html_safe
    else
      content_tag :span, class: 'group-title' do
        full_title.html_safe
      end
    end
  end

  def projects_lfs_status(group)
    lfs_status =
      if group.lfs_enabled?
        group.projects.select(&:lfs_enabled?).size
      else
        group.projects.reject(&:lfs_enabled?).size
      end

    size = group.projects.size

    if lfs_status == size
      'for all projects'
    else
      "for #{lfs_status} out of #{pluralize(size, 'project')}"
    end
  end

  def group_lfs_status(group)
    status = group.lfs_enabled? ? 'enabled' : 'disabled'

    content_tag(:span, class: "lfs-#{status}") do
      "#{status.humanize} #{projects_lfs_status(group)}"
    end
  end

  def group_issues(group)
    IssuesFinder.new(current_user, group_id: group.id).execute
  end

  def remove_group_message(group)
    _("You are going to remove %{group_name}. Removed groups CANNOT be restored! Are you ABSOLUTELY sure?") %
      { group_name: group.name }
  end

  private

  def group_title_link(group, hidable: false, show_avatar: false)
    link_to(group_path(group), class: "group-path breadcrumb-item-text js-breadcrumb-item-text #{'hidable' if hidable}") do
      output =
        if (show_new_nav? && group.try(:avatar_url) || (show_new_nav? && show_avatar)) && !Rails.env.test?
          image_tag(group_icon(group), class: "avatar-tile", width: 15, height: 15)
        else
          ""
        end

      output << simple_sanitize(group.name)
      output.html_safe
    end
  end
end
