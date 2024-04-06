library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mcp_blk is
    generic (
        dat_t : type := std_logic_vector(7 downto 0)
    );
    port (
        aready : out std_logic;   -- ready to receive next data
        adatain : in dat_t;
        asend : in std_logic;
        aclk : in std_logic;
        arst_n : in std_logic;
        bdata : out dat_t;
        bvalid : out std_logic;   -- bdata valid (ready)
        bload : in std_logic;
        bclk : in std_logic;
        brst_n : in std_logic
    );
end entity mcp_blk;

architecture RTL of mcp_blk is
    signal adata : dat_t;  -- internal data bus
    signal b_ack : std_logic;  -- acknowledge enable signal
    signal a_en : std_logic;   -- control enable signal
    signal bq2_en : std_logic; -- control - sync output
    signal aq2_ack : std_logic;  -- feedback - sync output
begin
    async : entity work.sync2
        port map (
            q => aq2_ack,
            d => b_ack,
            clk => aclk,
            rst_n => arst_n
        );

    bsync : entity work.sync2
        port map (
            q => bq2_en,
            d => a_en,
            clk => bclk,
            rst_n => brst_n
        );

    alogic : entity work.amcp_send
        port map (
            adata => adata,
            a_en => a_en,
            aready => aready,
            adatain => adatain,
            asend => asend,
            aq2_ack => aq2_ack,
            aclk => aclk,
            arst_n => arst_n
        );

    blogic : entity work.bmcp_recv
        port map (
            bdata => bdata,
            bvalid => bvalid,
            b_ack => b_ack,
            adata => adata,
            bload => bload,
            bq2_en => bq2_en,
            bclk => bclk,
            brst_n => brst_n
        );
end architecture RTL;