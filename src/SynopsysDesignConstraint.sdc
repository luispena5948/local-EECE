% main 50 MHz clock
create_clock -period ??? [ get_ports ???? ]
create_clock -period ??? -name main_clock_virt

% ADC 10 MHz clock
create_clock -period ??? [ get_ports ???? ]
create_clock -period ??? -name adc_clock_virt

% ADC derived clock
create_generated_clock -name clk_div -source [ get_pins ??? ] \
-divide_by ??? -multiply_by ??? [ get_pins ??? ]
