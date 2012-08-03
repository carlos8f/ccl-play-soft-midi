(defVar *graph* nil "the AudioUnit graph")
(defVar *synth-unit* nil "the synth unit")

(defVar *channel* 0 "MIDI channel")
(defVar *control-change* #xB "control change")
(defVar *program-change* #xC "program change")
(defVar *bank-msb-control* 0 "bank MSB control")
(defVar *bank-lsb-control* 32 "bank LSB control")
(defVar *note-on* #x9 "note on")

(objc:load-framework "AudioUnit" :audiounit)
(objc:load-framework "AudioToolbox" :audiotoolbox)

(defun create-synth ()
  "create the synth unit"
  (let ((Synth-Description (make-record
      :<a>udio<c>omponent<d>escription
      :component<m>anufacturer #$kAudioUnitManufacturer_Apple
      :component<f>lags 0
      :component<f>lags<m>ask 0
      :component<t>ype #$kAudioUnitType_MusicDevice
      :component<s>ub<t>ype #$kAudioUnitSubType_DLSSynth))
    (Limiter-Description (make-record
      :<a>udio<c>omponent<d>escription
      :component<m>anufacturer #$kAudioUnitManufacturer_Apple
      :component<f>lags 0
      :component<f>lags<m>ask 0
      :component<t>ype #$kAudioUnitType_Effect
      :component<s>ub<t>ype #$kAudioUnitSubType_PeakLimiter))
    (Output-Description (make-record
      :<a>udio<c>omponent<d>escription
      :component<m>anufacturer #$kAudioUnitManufacturer_Apple
      :component<f>lags 0
      :component<f>lags<m>ask 0
      :component<t>ype #$kAudioUnitType_Output
      :component<s>ub<t>ype #$kAudioUnitSubType_DefaultOutput)))
    (rlet ((AU-Graph :<aug>raph)
          (Synth-Node :<aun>ode)
          (Limiter-Node :<aun>ode)
          (Output-Node :<aun>ode)
          (Synth-Unit :<a>udio<u>nit))

      (print (#_NewAUGraph (pref AU-Graph :<aug>raph)))
      (print (#_AUGraphAddNode AU-Graph
             (pref Synth-Description :<a>udio<c>omponent<d>escription)
             (pref Synth-Node :<aun>ode)))
      #|
      (print (#_AUGraphAddNode AU-Graph
             (pref Limiter-Description :<a>udio<c>omponent<d>escription)
             (pref Limiter-Node :<aun>ode)))
      (print (#_AUGraphAddNode AU-Graph
             (pref Output-Description :<a>udio<c>omponent<d>escription)
             (pref Output-Node :<aun>ode)))

      (print (#_AUGraphOpen AU-Graph))
      (print (#_AUGraphConnectNodeInput AU-Graph
             (pref Synth-Node :<aun>ode)
             0
             (pref Limiter-Node :<aun>ode)
             0))
      (print (#_AUGraphConnectNodeInput AU-Graph
             (pref Limiter-Node :<aun>ode)
             0
             (pref Output-Node :<aun>ode)
             0))
      (print (#_AUGraphInitialize AU-Graph))
      
      (print (#_AUGraphNodeInfo AU-Graph
             (pref Synth-Node :<aun>ode)
             (#_NewPtr 4)
             Synth-Unit))
      |#

      Synth-Unit)))

(defun dispose-graph()
  "clean up the graph object"
  (#_AUGraphStop *graph*)
  (#_DisposeAUGraph *graph*))

(defun play()
  "play a scale"
  ; create the graph and synth
  (create-synth)
  ; set the bank
  (#_MusicDeviceMIDIEvent *synth-unit*
                          (logior (ash *control-change* 4) *channel*)
                          *bank-msb-control*
                          0
                          0)

  (#_MusicDeviceMIDIEvent *synth-unit*
                          (logior (ash *program-change* 4) *channel*)
                          0 ; program change number
                          0 ; ?
                          0) ; sample offset

  
  (#_AUGraphStart *graph*)

  (#_MusicDeviceMIDIEvent *synth-unit*
                          (logior (ash *note-on* 4) *channel*)
                          60 ; note number
                          127 ; on velocity
                          0) ; ?
  (sleep 5)

  (#_MusicDeviceMIDIEvent *synth-unit*
                          (logior (ash *note-on* 4) *channel*)
                          60 ; note number
                          0 ; off velocity
                          0) ; ?

  (dispose-graph))
