structure Main =
struct
structure F = Frame
structure T = Tree
structure C = Canon
structure R = Reg_Alloc
                  
fun emitproc out (F.PROC {body, frame}) =
    let (* val _ = print ("emit " ^ F.name frame ^ "\n") *)
        val saytemp = F.saytemp
        
        val stms = Canon.linearize body
        val stms' = Canon.traceSchedule (Canon.basicBlocks stms)
        val instrs = List.concat (map (MipsGen.codegen frame) stms')
        
        (* register allocation *)
        val (instrs, allocation) = R.alloc (instrs, frame)

        val {prolog, body = instrs', epilog} = F.procEntryExit3 (frame, instrs)
        val format0 = Assem.format saytemp
    in
        app (fn i => TextIO.output (out, format0 i)) instrs';
    end
  | emitproc out (F.STRING (lab, s)) = TextIO.output(out, F.string (lab, s))

fun withOpenFile fname f = 
    let
        val out = TextIO.openOut fname
    in (f out before TextIO.closeOut out)
       handle e => (TextIO.closeOut out; raise e)
    end 

fun compile filename = 
    let
        val _ = (Temp.reset (Frame.tempReset); MakeGraph.reset ())
        val absyn = Parse.parse filename
        val frags = (FindEscape.findEscape absyn; Semant.transProg absyn)
    in
        if !ErrorMsg.anyErrors
        then ()
        else withOpenFile (filename ^ ".s")
                          (fn out => (app (emitproc out) frags))
    end

end
