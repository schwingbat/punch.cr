def format_duration(duration : Time::Span, *, tablified = false)
  str = ""

  seconds = duration.total_seconds.to_i
  minutes = (seconds / 60).to_i
  hours = (minutes / 60).to_i

  seconds -= minutes * 60
  minutes -= hours * 60

  if hours > 0
    str += hours.to_s + "h "
  end
  if minutes > 0 || str.size > 0
    m = minutes.to_s
    m = m.rjust(2) if tablified
    str += m + "m "
  end
  s = seconds.to_s
  s = s.rjust(2) if tablified
  str += s + "s "

  str.strip
end