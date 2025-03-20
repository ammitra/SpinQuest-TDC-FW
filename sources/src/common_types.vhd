---------------------------------------------------------------------------------------------------------
--! \file common_types.vhd
--! \brief VHDL 2008 package containing common generic types and useful functions.
--! 
--! \author Amitav Mitra, amitra3@jhu.edu
---------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; 
use IEEE.NUMERIC_STD.all;
use ieee.math_real.all;

--! \brief Common types and useful functions.
package common_types is

   -- Typing std_logic(_vector) is annoying
   subtype sl is std_logic;
   subtype slv is std_logic_vector;
   
   -- Not supported in block design! (VHDL 2008)
   type SlvArray is array (natural range <>) of slv;
   type IntArray is array (natural range <>) of integer;
   
   -- Very useful functions
   function isPowerOf2 (number       : natural) return boolean;   --! Returns true if number is a power of 2
   function isPowerOf2 (vector       : slv) return boolean;       --! Returns true if integer representation of SLV is a power of 2
   function log2 (constant number    : integer) return natural;   --! Returns log base 2 of an integer
   function bitSize (constant number : natural) return positive;  --! Returns number of bits needed to represent a natural
   function toSlv(ARG : integer; SIZE : integer) return slv;
   function isodd (n: positive) return natural;

end package;

--! \brief Function definitions
package body common_types is

   function isPowerOf2 (number : natural) return boolean is
   begin
      return isPowerOf2(toSlv(number, 32));
   end function isPowerOf2;
   
   function isPowerOf2 (vector : slv) return boolean is
   begin
      return (unsigned(vector) /= 0) and
         (unsigned(unsigned(vector) and (unsigned(vector)-1)) = 0);
   end function isPowerOf2;
   
   --! \brief Finds the log base 2 of an integer
   --!
   --! \details Input is rounded up to the nearest power of two. Therefore `log2(5) = log2(8) = 3`.
   --!
   --! \param number    Integer to find log base 2 of
   function log2(constant number : integer) return natural is
   begin
      if (number < 2) then
         return 1;
      end if;
      return integer(ceil(ieee.math_real.log2(real(number))));
   end function;

   --! \brief Finds number of bits needed to represent a number
   --! \param number    Number you wish to find the number of bits needed to represent
   function bitSize (constant number : natural ) return positive is
   begin
      if (number = 0 or number = 1) then
         return 1;
      else
         if (isPowerOf2(number)) then
            return log2(number) + 1;
         else
            return log2(number);
         end if;
      end if;
   end function;
   

   --! \brief Convert an integer to a STD_LOGIC_VECTOR representation
   --! \param ARG    Number to convert
   --! \param SIZE   Size of the STD_LOGIC_VECTOR to store it
   function toSlv(ARG : integer; SIZE : integer) return slv is
   begin
      if (arg < 0) then
         return slv(to_unsigned(0, SIZE));
      end if;
      return slv(to_unsigned(ARG, SIZE));
   end;
   
   --! \brief Returns 1 if number is odd, 0 if even
   --! \param n   Number to determine if odd or even.
   function isodd (n: positive) return natural is
   begin
      if (n/2 * 2 < n) then
         return 1;
      else 
         return 0;
      end if;
   end function;
   
end package body common_types;
