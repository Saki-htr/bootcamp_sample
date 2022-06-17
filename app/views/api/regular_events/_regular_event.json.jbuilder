json.(regular_event, :id, :title, :wip, :wday, :start_at, :end_at, :finished)
json.title regular_event.title
json.wday regular_event.wday
json.start_at_localized l regular_event.start_at, format: :time_only
json.end_at_localized l regular_event.end_at, format: :time_only
json.finished regular_event.finished
json.comments_count regular_event.comments.size
json.url regular_event_url(regular_event)
json.user regular_event.user, partial: "api/users/user", as: :user
