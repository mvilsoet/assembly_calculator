# assembly_calculator
Assembly-LC3 five-function calculator 

The following program is an implementation of a five-function calculator using a stack. +,-,*,/ are built using a subroutine call inside of the Evaluate subroutine. The ^ then calls several instances of the * subroutine to complete the calculation. All subroutines in this program are callee-saved so that they may be copied and reused in future programs.

Suggested to run this code on an online LC-3 simulator since the language is ancient and irritating to run natively. 
[Try this simulator on wchargin](https://wchargin.com/lc3web/ "LC-3 Simulator")
