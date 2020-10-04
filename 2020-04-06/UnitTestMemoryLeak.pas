unit UnitTestMemoryLeak;

interface

implementation
uses
  windows;
initialization
finalization
 
  if AllocMemCount <> 0 then
    MessageBox(0, 'An unexpected memory leak has occurred.',
    'Unexpected Memory Leak', MB_OK or MB_ICONERROR or MB_TASKMODAL);

end.
 