(defVar *graph* nil "the AudioUnit graph")
(defVar *synth-unit* nil "the synth unit")
(defVar *channel* 0 "MIDI channel")

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
      (setq *synth-unit* Synth-Unit))))
