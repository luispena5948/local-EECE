library ieee;
use ieee.std_logic_1164.all;


--sync signals from different clock domains
entity sync2 is
	port(
		q:				out	std_logic;
		d:				in		std_logic;
		clk:			in		std_logic;	
		rst_n:		in		std_logic
	);

end entity sync2;


architecture rtl of sync2 is

	signal q1 : std_logic; 		-- 1st stage ff output

begin
	process(clk, rst_n)
	begin
		
		if rst_n = '0' then
			q	<= '0';
			q1 <= '0';
		elsif rising_edge(clk) then
			q	<=	q1;
			q1	<=	d;
		end if;
		
	end process;
end architecture rtl;