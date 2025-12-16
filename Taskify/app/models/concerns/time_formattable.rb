module TimeFormattable
  extend ActiveSupport::Concern

  def time_ago_in_words_es(time_reference = created_at)
    time_diff = Time.current - time_reference

    case time_diff
    when 0..59
      seconds = time_diff.to_i
      "hace #{seconds} #{ seconds == 1 ? 'segundo' : 'segundos' }"
    when 60..3599
      minutes = (time_diff / 60).to_i
      "hace #{minutes} #{ minutes == 1 ? 'minuto' : 'minutos' }"
    when 3600..86399
      hours = (time_diff / 3600).to_i
      "hace #{hours} #{ hours == 1 ? 'hora' : 'horas' }"
    when 86400..604799
      days = (time_diff / 86400).to_i
      "hace #{days} #{ days == 1 ? 'día' : 'días' }"
    else
      time_reference.strftime("%d/%m/%Y")
    end
  end

  def created_at_relative_es
    # Cache the relative time calculation
    @created_at_relative_es ||= time_ago_in_words_es(created_at)
  end
end
