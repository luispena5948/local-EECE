library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ads;
use ads.dat_t_pkg.all;

entity dp_ram2 is
    port(
        q:		out	dat_t;
        d:		in		dat_t;
        waddr:	in		std_logic;
        raddr:	in		std_logic;
        we:		in		std_logic;
        clk:	in		std_logic
    );
end entity dp_ram2;

architecture RTL of dp_ram2 is
    type mem_t is array (0 to 1) of dat_t;
    signal mem : mem_t;
begin
    process (clk)
    begin
        if (rising_edge(clk)) then
            if (we = '1') then
                mem(to_integer(unsigned(waddr))) <= d;
            end if;
        end if;
    end process;

    q <= mem(to_integer(unsigned(raddr)));
end architecture RTL;