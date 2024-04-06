library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bmcp_recv is
	port (
		bdata		: out	std_logic_vector(7 downto 0);
		bvalid	: out	std_logic;  							-- bdata valid
		b_ack		: out	std_logic;								-- acknowledge signal
		adata		: in	std_logic_vector(7 downto 0);		-- unsynchronized adata
		bload		: in	std_logic;    							-- load data and acknowledge receipt
		bq2_en	: in	std_logic;								-- synchronized enable input
		bclk		: in	std_logic;
		brst_n	: in	std_logic
	);
end entity bmcp_recv;

architecture RTL of bmcp_recv is
	signal b_en:						std_logic;  		-- enable pulse from pulse generator
	signal bload_data:				std_logic;
	signal bvalid_internal:			std_logic;
	signal bload_internal:			std_logic;
begin

	bvalid				<= bvalid_internal;
	bload_internal		<= bload;
	
	-- Pulse Generator
	pg1 : entity work.plsgen
		port map (
			pulse	=> b_en,
			q		=> open,
			d		=> bq2_en,
			clk	=> bclk,
			rst_n	=> brst_n
		);

	-- Data ready/acknowledge FSM
	fsm : entity work.back_fsm
		port map (
			bvalid	=> bvalid_internal,
			bload		=> bload_internal,
			b_en		=> b_en,
			bclk		=> bclk,
			brst_n	=> brst_n
		);

	-- Load next data word
	 bload_data <= (bvalid_internal and bload_internal);
	 

	-- Toggle-flop controlled by bload_data
	process (bclk, brst_n)
	begin
		if (brst_n = '0') then
			b_ack <= '0';
		elsif (rising_edge(bclk)) then
			if (bload_data = '1') then
				b_ack <= '1';
			end if;
		end if;
	end process;

	process (bclk, brst_n)
	begin
		if (brst_n = '0') then
			bdata <= (others => '0');
		elsif (rising_edge(bclk)) then
			if (bload_data = '1') then
				bdata <= adata;
			end if;
		end if;
	end process;
end architecture RTL;