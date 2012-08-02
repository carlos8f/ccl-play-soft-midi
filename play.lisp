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
  (let ((AU-Graph (#_NewPtr 4))
    (Synth-Unit (#_NewPtr 4))
    (Synth-Description (make-record
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
    (#_NewAUGraph AU-Graph)
    (when (%null-ptr-p AU-Graph) (error "could not create AUGraph"))
    (rlet ((Synth-Node :<aun>ode)
          (Limiter-Node :<aun>ode)
          (Output-Node :<aun>ode))

      (setq *graph* AU-Graph)

      (#_AUGraphAddNode *graph* Synth-Description Synth-Node)
      (#_AUGraphAddNode *graph* Limiter-Description Limiter-Node)
      (#_AUGraphAddNode *graph* Output-Description Output-Node)
      (#_AUGraphOpen *graph*)
      (#_AUGraphConnectNodeInput *graph* (%ptr-to-int Synth-Node) 0 (%ptr-to-int Limiter-Node) 0)
      (#_AUGraphConnectNodeInput *graph* (%ptr-to-int Limiter-Node) 0 (%ptr-to-int Output-Node) 0)
      (#_AUGraphNodeInfo *graph* (%ptr-to-int Synth-Node) Synth-Description Synth-Unit)
      (when (%null-ptr-p Synth-Unit) (error "could not get NodeInfo for synth"))
      (setq *synth-unit* Synth-Unit)
      (#_AUGraphInitialize *graph*)
      )))

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
