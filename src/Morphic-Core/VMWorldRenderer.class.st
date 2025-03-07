"
I know how to render the world using the VM backend.
"
Class {
	#name : #VMWorldRenderer,
	#superclass : #AbstractWorldRenderer,
	#instVars : [
		'display',
		'canvas',
		'deferredUpdateMode'
	],
	#category : #'Morphic-Core-Worlds'
}

{ #category : #accessing }
VMWorldRenderer class >> isApplicableFor: aWorld [

    ^ Smalltalk isHeadless not
]

{ #category : #accessing }
VMWorldRenderer class >> priority [ 

	^ 1
]

{ #category : #operations }
VMWorldRenderer >> activateCursor: aCursor withMask: maskForm [

	aCursor beCursorWithMask: maskForm

]

{ #category : #accessing }
VMWorldRenderer >> actualScreenSize [

	<primitive: 106>

	self primitiveFailed
]

{ #category : #'display box access' }
VMWorldRenderer >> assuredCanvas [
	(self canvas isNil
		or: [ self canvas extent ~= self viewBox extent
				or: [ self canvas form depth ~= Display depth ] ])
		ifTrue:
			[ "allocate a new offscreen canvas the size of the window" 
				self canvas: (Display defaultCanvasClass extent: self viewBox extent) ].
	^ self canvas
]

{ #category : #accessing }
VMWorldRenderer >> canvas [

	^ canvas
]

{ #category : #accessing }
VMWorldRenderer >> canvas: x [ 
	canvas := x
]

{ #category : #events }
VMWorldRenderer >> checkForNewScreenSize [

	"Check whether the screen size has changed and if so take appropriate actions"

	Display extent = DisplayScreen actualScreenSize ifTrue: [^ Display].

   Display setExtent: self actualScreenSize depth: 32.
   Display beDisplay.

	world worldState realWindowExtent: self actualScreenSize.

	world restoreMorphicDisplay.

]

{ #category : #activation }
VMWorldRenderer >> deactivate [

	InputEventSensor default shutDown.
	
	Display shutDown.

	InputEventFetcher default shutDown.

]

{ #category : #operations }
VMWorldRenderer >> deferUpdates: aValue [

	^ Display deferUpdates: aValue
]

{ #category : #operations }
VMWorldRenderer >> deferUpdatesDuring: aBlock [

	| previousDeferredUpdateMode |
	previousDeferredUpdateMode := deferredUpdateMode.
	[deferredUpdateMode := (self doDeferredUpdatingFor: world)
		ifTrue: [ VMDisplayDeferredUpdateMode new ]
		ifFalse: [ self assuredCanvas. VMDisplayDirectUpdateMode new ].
	
	aBlock value
	
	] ensure: [ 
		deferredUpdateMode := previousDeferredUpdateMode.
		self deferUpdates: false.
		self forceDisplayUpdate ]
]

{ #category : #activation }
VMWorldRenderer >> doActivate [

    InputEventFetcher default startUp.
    InputEventSensor installMouseDecodeTable.
    InputEventSensor default startUp.
    
    Display setExtent: self actualScreenSize depth: 32.
    Display beDisplay.

    canvas := nil.
    display := nil.

    self assuredCanvas.
    DisplayScreen refreshHostWindowTitle.
    Display forceDisplayUpdate.
    world displayWorld.
]

{ #category : #operations }
VMWorldRenderer >> doDeferredUpdatingFor: aWorld [
"If this platform supports deferred updates, then make my canvas be the Display (or a rectangular portion of it), set the Display to deferred update mode, and answer true. Otherwise, do nothing and answer false. One can set the class variable DisableDeferredUpdates to true to completely disable the deferred updating feature."

	(Display deferUpdates: true) ifNil: [^ false].  "deferred updates not supported"

	(self canvas notNil and: [self canvas form == Display]) ifFalse: [
			aWorld viewBox: self viewBox.    "do first since it may clear canvas"
			self canvas: (Display getCanvas copyClipRect: Display boundingBox)].

	^ true
]

{ #category : #operations }
VMWorldRenderer >> drawDuring: aBlock [
	
	self canvas ifNotNil: [ 
		aBlock value: self canvas.
	]
]

{ #category : #operations }
VMWorldRenderer >> forceDamageToScreen: allDamage [

	^ Display forceDamageToScreen: allDamage.
	
]

{ #category : #operations }
VMWorldRenderer >> forceDisplayUpdate [

	^ Display forceDisplayUpdate
]

{ #category : #operations }
VMWorldRenderer >> fullscreenMode: aValue [

	Display fullscreenMode: aValue.
	self checkForNewScreenSize.
]

{ #category : #accessing }
VMWorldRenderer >> icon: aForm [ 

	"Do nothing.
	This is not supported anymore with the old VM world renderers.
	Use the new headless + SDL instead.
	
	Alternatively, if you're on windows you can try to use the following primitive from DisplayScreen that receives a path to a .ico file.
	This primitive only works on Windows.
	
	DisplayScreen hostWindowIcon: path.
	"
]

{ #category : #rendering }
VMWorldRenderer >> invalidate [

	self canvas: nil
]

{ #category : #operations }
VMWorldRenderer >> updateDamage: allDamage [
	
	"quickly copy altered rects of canvas to Display:"
	deferredUpdateMode
		updateDamage: allDamage
		ofWorld: world
		onRenderer: self.
]

{ #category : #events }
VMWorldRenderer >> updateToNewResolution [

	
]

{ #category : #'display box access' }
VMWorldRenderer >> usableArea [

	^ Display usableArea
]

{ #category : #'display box access' }
VMWorldRenderer >> viewBox [ 

	^ Display boundingBox
]
