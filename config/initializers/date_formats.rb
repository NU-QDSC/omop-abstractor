my_formats = {
	:month => '%Y-%m',
	:date => '%m/%d/%Y',
	:short_date => '%y/%m/%d',
	:date_time12  => "%m/%d/%Y %I:%M%p",
	:date_time24  => "%m/%d/%Y %H:%M"
}

Time::DATE_FORMATS.merge!(my_formats)
Date::DATE_FORMATS.merge!(my_formats)