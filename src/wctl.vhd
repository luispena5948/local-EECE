library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity wctl is
	port (
		wrdy:			out	std_logic;
		wptr: 		out	std_logic;
		we:			out	std_logic;
		
		wput:			in		std_logic;
		wq2_rptr:	in		std_logic;
		wclk:			in		std_logic;
		wrst_n: 		in		std_logic
	);
end entity wctl;

architecture RTL of wctl is
	--outputs
	signal	wrdy_line:		std_logic;
	signal	we_line:			std_logic;
	signal	wptr_line:		std_logic;
	--inputs
	signal	wput_line:		std_logic;
	signal	wq2_rptr_line:	std_logic;	

begin
	--outputs
	wrdy	<=	wrdy_line;
	we		<=	we_line;
	wptr	<=	wptr_line;
	
	--inputs
	wput_line		<=	wput;
	wq2_rptr_line	<=	wq2_rptr;	
	
	
	we_line	<=	(wrdy_line and wput_line);
	--we		 	<= wput_line;
	
	wrdy_line <= not (wq2_rptr_line xor wptr_line);

	process (wclk, wrst_n)
	begin
		if (wrst_n = '0') then
			wptr_line <= '0';
		elsif (rising_edge(wclk)) then
			wptr_line <= (wptr_line xor we_line);
		end if;
	end process;
end architecture RTL;
