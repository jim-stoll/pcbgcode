#!/usr/bin/env ruby

#
# Write the convert_units() function to be inserted into pcb-gcode-setup.ulp.
#

# First pass - collect names of real variables
@conversions = [];
File.open("pcb-gcode-setup.ulp").each_line { |line|
  if line !~ /\/\/ DO NOT CONVERT/
    if line =~ /dlgRealEdit\(([A-Z_]+)/
      setting = $1
      conv_string = "    #{setting} = convert(#{setting}, m_current_units, new_units);\n"
      if line =~ /\/\/ CONVERT FIRST/
        @conversions.unshift(conv_string)
      else
        @conversions.push(conv_string)
      end
    end
  end
}

def write_conversion_code
result = ""

result = result + "
void convert_units(int new_units)
{
"

@conversions.each { |conversion|
  result << conversion
}

result = result + "
    set_uom_suffix(OUTPUT_UNITS);
    dlgRedisplay();
    m_current_units = new_units;
}

"

end

# Second pass - substitute the conversion code where it should be.
ST_BEFORE = 1
ST_INSERT_CODE = 2
ST_INSIDE = 3
ST_AFTER  = 4
state = ST_BEFORE

File.open("pcb-gcode-setup.new", "w") { |output|

  File.open("pcb-gcode-setup.ulp").each_line { |line|

    if line =~ /\/\/ UNIT CONVERSION BEGIN TAG DO NOT REMOVE/
      state = ST_INSERT_CODE
    elsif line =~ /\/\/ UNIT CONVERSION END TAG DO NOT REMOVE/
      state = ST_AFTER
    end
  

    case state
    
    when ST_BEFORE
      output << line

    when ST_INSERT_CODE
      output << line
      output << write_conversion_code
      state = ST_INSIDE
    
    when ST_INSIDE
      # no output

    when ST_AFTER
      output << line
    end
  }
}

if FileTest.exists?("pcb-gcode-setup.old")
  File.delete("pcb-gcode-setup.old")
end

File.rename("pcb-gcode-setup.ulp", "pcb-gcode-setup.old")
File.rename("pcb-gcode-setup.new", "pcb-gcode-setup.ulp")
File.delete("pcb-gcode-setup.old")
