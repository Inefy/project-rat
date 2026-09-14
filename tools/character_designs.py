"""Original faceted cartoon cast, designed to read in a 50–150px arena sprite.

Shared materials and modelling primitives; deliberately different body plans.
The front of every model is -Y, with the ground at Z=0.
"""
import math

IDENTITIES = {
    'rat': 'Big pink ears, red scarf, blue waistcoat, buck teeth and seed blaster',
    'bird': 'Compact blue dart, outstretched wings, swept yellow quiff and giant beak',
    'cat': 'Black long-legged cat, charcoal face, green ring eyes, human hands, bloodied fangs and S-shaped knife tail',
    'owl': 'Round chestnut barrel, huge cream eye disks and heavy brow tufts',
    'snake': 'Lime S-neck above a broad coil, flat snout, cobra hood and forked tongue',
    'raccoon': 'Hunched slate bandit, black mask, striped tail and oversized bin lid',
    'fox': 'Tall orange rake, long muzzle, black stockings and huge cream-tipped tail',
    'alpha_cat': 'Magenta monarch, triangular burgundy cape and crooked gold crown',
    'junkyard_dog': 'Wide square bulldog, heavy jowls, underbite and red spiked collar',
    'barn_owl': 'Ivory heart face, swept dark wings, teal academic gown and mortarboard',
}


def build_character(k, ball, box, cone, rod, ring):
    def eye(x, y, z, width=.19, height=.22, mood=0):
        ball('Eye white', (x, y, z), (width, .10, height), 'cream')
        ball('Pupil', (x+.025, y-.09, z-.025), (width*.34, .035, height*.52), 'ink')
        ball('Eye glint', (x+.045, y-.12, z+.03), (.025, .015, .03), 'cream')
        if mood:
            lid=ball('Heavy eyelid', (x, y-.025, z+height*.72), (width*1.1, .11, height*.40), k)
            lid.rotation_euler.y=mood
        rod('Expression brow', (x-width, y-.06, z+height+.05-mood*.10),
            (x+width, y-.06, z+height+.05+mood*.10), .055, 'ink')

    def pair(y, z, spread=.26, width=.19, height=.22, mood=0):
        for s in [-1, 1]:
            eye(s*spread, y, z, width, height, s*mood)

    def ears(z, spread, width, height, color, inner='pink'):
        for s in [-1, 1]:
            e=cone('Pointed ear', (s*spread, .015, z), (width, .20, height), color)
            e.rotation_euler.y=s*.17
            e=cone('Inner ear', (s*spread, -.16, z+.015), (width*.52, .035, height*.65), inner)
            e.rotation_euler.y=s*.17

    def tail(points, widths, colors):
        for i, (point, width) in enumerate(zip(points, widths)):
            color=colors[i % len(colors)]
            ball('Tail segment', point, (width, width, width*1.15), color)
            if i:
                rod('Tail join', points[i-1], point, min(widths[i-1], width)*.85, color)

    if k == 'rat':
        ball('Lean body', (0, .05, .92), (.43, .34, .65), 'rat')
        ball('Blue waistcoat', (0, .04, .94), (.46, .36, .41), 'denim')
        ball('Shirt front', (0, -.30, 1.00), (.23, .09, .30), 'cream')
        for s in [-1, 1]:
            rod('Leg', (s*.24, 0, .52), (s*.27, -.04, .20), .14, 'rat')
            ball('Pink foot', (s*.27, -.19, .15), (.20, .34, .14), 'pink')
            rod('Sleeve', (s*.40, .02, 1.15), (s*.54, -.22, .91), .18, 'denim')
            ball('Pink hand', (s*.53, -.36, .88), (.17, .16, .18), 'pink')
        ball('Rat head', (0, -.02, 1.81), (.50, .40, .48), 'rat')
        for s in [-1, 1]:
            z=2.32 + (0.08 if s < 0 else 0)
            ball('Satellite ear', (s*.48, .04, z), (.35, .14, .47), 'rat')
            ball('Pink ear center', (s*.48, -.085, z), (.26, .05, .36), 'pink')
        pair(-.39, 1.92, .23, .19, .23, .4)
        ball('Rat muzzle', (0, -.55, 1.60), (.31, .31, .19), 'cream')
        ball('Pink nose', (0, -.85, 1.66), (.13, .10, .095), 'pink')
        ball('Grin', (0, -.54, 1.40), (.24, .14, .12), 'ink')
        for s in [-1, 1]:
            tooth=box('Buck tooth', (s*.095, -.68, 1.37), (.08, .06, .16), 'cream')
            tooth.rotation_euler.y=s*.10
            for z in [1.57, 1.67]:
                rod('Whisker', (s*.25, -.62, z), (s*.65, -.60, z+.06*s), .018, 'ink')
        ring('Red scarf', (0, 0, 1.35), .35, .12, 'red')
        flap=cone('Scarf flying end', (-.57, .22, 1.29), (.24, .10, .43), 'red')
        flap.rotation_euler.y=-.7
        tail([(.08+i*.12, .30+i*.10, .33+math.sin(i*.5)*.15) for i in range(9)],
             [.065-i*.004 for i in range(9)], ['pink'])
        rod('Seed blaster', (.48, -.32, .92), (.48, -.93, .92), .16, 'brown')
        rod('Green barrel', (.48, -.87, .92), (.48, -1.13, .92), .20, 'green')
        ball('Barrel bore', (.48, -1.14, .92), (.13, .024, .13), 'ink')

    elif k == 'bird':
        ball('Flying blue egg', (0, .08, 1.19), (.48, .55, .57), 'bird')
        ball('Golden chest', (0, -.36, 1.04), (.30, .12, .32), 'gold')
        ball('Forward head', (0, -.25, 1.66), (.46, .41, .40), 'bird')
        pair(-.59, 1.76, .22, .17, .18, .9)
        beak=cone('Huge wedge beak', (0, -.92, 1.46), (.27, .19, .42), 'gold')
        beak.rotation_euler.x=math.pi/2
        rod('Beak smirk', (-.23, -.85, 1.44), (.23, -.85, 1.40), .024, 'brown')
        for s in [-1, 1]:
            rod('Wing leading edge', (s*.30, .05, 1.34), (s*.94, .14, 1.53), .15, 'bird')
            for i in range(3):
                feather=ball('Splayed flight feather', (s*(.72+i*.18), .18+i*.07, 1.39-i*.11), (.29, .17, .12), 'navy')
                feather.rotation_euler.y=s*.35
            rod('Spindly leg', (s*.20, .02, .77), (s*.27, -.05, .35), .065, 'gold')
            ball('Comical bird foot', (s*.27, -.21, .29), (.18, .30, .08), 'gold')
        for i in range(3):
            quiff=cone('Swept quiff', (-.19+i*.18, .0+i*.12, 2.15+i*.06), (.15, .21, .35), 'gold')
            quiff.rotation_euler.x=-.65
        for s in [-1, 0, 1]:
            rod('Tail feather', (s*.12, .45, .98), (s*.24, .88, 1.18), .095, 'navy')

    elif k == 'cat':
        from cat_model import build_cat
        return build_cat()

    elif k == 'owl':
        ball('Round feather barrel', (0, .08, 1.05), (.77, .51, .88), 'owl')
        ball('Chest feathers', (0, -.36, .81), (.52, .14, .49), 'ochre')
        for s in [-1, 1]:
            ball('Broad face disk', (s*.32, -.41, 1.61), (.39, .13, .44), 'cream')
            eye(s*.32, -.55, 1.66, .23, .26, -s*.65)
            tuft=cone('Heavy horn tuft', (s*.60, .06, 2.04), (.20, .22, .41), 'brown')
            tuft.rotation_euler.y=s*.45
            ball('Tucked wing', (s*.67, .04, .99), (.23, .36, .53), 'brown')
            for z in [.72, .95, 1.18]:
                rod('Wing feather bar', (s*.79, -.17, z), (s*.80, .18, z+.09), .035, 'ochre')
            ball('Talons', (s*.32, -.20, .17), (.23, .28, .12), 'gold')
        for x,z in [(-.23,.90),(.23,.90),(0,.64)]:
            cone('Chest chevron', (x,-.50,z), (.085,.025,.13), 'brown')
        beak=cone('Hooked beak', (0, -.67, 1.30), (.15,.14,.25), 'gold')
        beak.rotation_euler.x=math.pi*.80

    elif k == 'snake':
        for i in range(15):
            a=i*math.tau/14
            ball('Heavy coil', (math.cos(a)*.67, math.sin(a)*.46, .28+i*.013), (.28,.29,.25), 'snake')
        for i in range(10):
            t=i/9
            x=math.sin(t*math.pi*1.4)*.29
            ball('S neck', (x,.09-t*.22,.55+t*1.13), (.25,.24,.24), 'snake')
            ball('Yellow belly scute', (x,-.12-t*.22,.55+t*1.13), (.18,.055,.12), 'lime')
        ball('Cobra hood', (-.03,.10,1.46), (.58,.14,.55), 'snake')
        for s in [-1,1]:
            ball('Hood marking', (s*.36,-.015,1.50), (.14,.025,.31), 'lime')
        ball('Flat snake skull', (-.22,-.26,1.94), (.49,.41,.25), 'snake')
        ball('Wide blunt snout', (-.22,-.61,1.81), (.45,.34,.17), 'lime')
        for s in [-1,1]:
            eye(-.22+s*.27,-.53,2.09,.17,.19,s*.5)
            ball('Nostril', (-.22+s*.17,-.89,1.90), (.037,.025,.025), 'ink')
        rod('Snake grin', (-.59,-.77,1.74), (.15,-.77,1.74), .028, 'ink')
        rod('Tongue', (-.22,-.85,1.72), (-.22,-1.16,1.68), .032, 'red')
        for s in [-1,1]:
            rod('Tongue fork', (-.22,-1.16,1.68), (-.22+s*.13,-1.29,1.70), .025, 'red')
        tail([(.60,.32,.39),(.91,.28,.28),(1.15,.13,.20)], [.16,.12,.045], ['snake'])

    elif k == 'raccoon':
        ball('Hunched shoulders', (0,.18,1.05), (.68,.46,.65), 'raccoon')
        box('Work apron', (0,-.21,.80), (.45,.16,.40), 'navy')
        rod('Apron belt', (-.45,-.39,.93), (.45,-.39,.93), .06, 'brown')
        box('Belt buckle', (0,-.44,.94), (.09,.025,.07), 'gold')
        ball('Bandit head', (-.05,-.12,1.75), (.59,.40,.42), 'raccoon')
        for s in [-1,1]:
            ball('Round ear', (s*.46,.02,2.11), (.20,.14,.23), 'ink')
            ball('Ear center', (s*.46,-.10,2.11), (.12,.045,.14), 'raccoon')
            mask=ball('Black eye mask', (s*.25-.05,-.46,1.82), (.30,.10,.23), 'ink')
            mask.rotation_euler.y=s*.15
            eye(s*.25-.05,-.55,1.84,.17,.15,s*.8)
            ball('Boot paw', (s*.33,-.18,.16), (.23,.32,.16), 'ink')
            rod('Stocky arm', (s*.54,0,1.23), (s*.65,-.26,.87), .22, 'raccoon')
        ball('Pointed muzzle', (-.05,-.52,1.52), (.26,.29,.16), 'cream')
        ball('Bandit nose', (-.05,-.82,1.58), (.14,.09,.10), 'ink')
        tail([(-.42-i*.12,.36+i*.05,.39+i*.18) for i in range(6)], [.23,.25,.27,.27,.25,.20], ['raccoon','ink'])
        lid=ring('Huge bin lid rim', (.70,-.59,.88), .61,.07,'metal'); lid.rotation_euler.x=math.pi/2
        ball('Dented bin lid', (.70,-.56,.88), (.59,.10,.59), 'metal')
        for s in [-1,1]:
            rod('Lid rib', (.70+s*.19,-.67,.47), (.70+s*.19,-.67,1.29), .026,'cream')
        box('Lid handle', (.70,-.72,.90), (.15,.06,.08), 'ink')

    elif k == 'fox':
        for s in [-1,1]:
            rod('Long black stocking', (s*.20,.05,.82), (s*.27,-.02,.20), .115,'ink')
            ball('Long narrow foot', (s*.27,-.21,.14), (.17,.34,.12),'ink')
        ball('Lanky torso', (0,.07,1.26), (.34,.29,.65),'fox')
        ball('Cream shirt', (0,-.20,1.37), (.22,.07,.40),'cream')
        for s in [-1,1]:
            rod('Thin arm', (s*.31,0,1.63), (s*.53,-.08,1.08), .12,'fox')
            ball('Black glove', (s*.54,-.12,1.02), (.13,.13,.18),'ink')
        ball('Narrow fox skull', (0,-.05,2.02), (.40,.32,.38),'fox')
        ears(2.45,.31,.20,.48,'fox','cream')
        pair(-.36,2.13,.22,.16,.18,.9)
        snout=cone('Long tapered muzzle', (0,-.68,1.89), (.26,.20,.43),'cream'); snout.rotation_euler.x=math.pi/2
        ball('Fox nose', (0,-1.08,1.89), (.12,.08,.085),'ink')
        rod('Smug grin', (-.18,-.70,1.78), (.18,-.70,1.78), .024,'ink')
        tail([(.20,.31,.65),(.50,.49,.91),(.79,.55,1.24),(.99,.55,1.61),(1.06,.49,1.92),(1.04,.39,2.16)],
             [.22,.32,.40,.38,.30,.17], ['fox','fox','fox','fox','cream','cream'])
        cone('Tail tip', (1.02,.36,2.35), (.16,.15,.24),'cream')

    elif k == 'alpha_cat':
        cone('Royal cape silhouette', (0,.21,1.04), (1.10,.61,1.00),'wine')
        ball('Royal belly', (0,-.06,1.00), (.76,.49,.71),'alpha_cat')
        ball('Cream royal bib', (0,-.49,1.05), (.47,.10,.43),'cream')
        for s in [-1,1]:
            rod('Ermine cape trim', (s*.33,-.23,1.60), (s*.88,-.16,.31), .12,'cream')
            ball('Royal slipper', (s*.48,-.29,.16), (.29,.36,.15),'gold')
            ball('Imperious paw', (s*.78,-.12,1.28), (.28,.25,.35),'alpha_cat')
        ball('Royal broad head', (0,-.03,1.98), (.75,.46,.49),'alpha_cat')
        ears(2.34,.55,.24,.31,'alpha_cat')
        pair(-.46,2.09,.32,.23,.21,-.6)
        for s in [-1,1]:
            ball('Royal cheek', (s*.30,-.49,1.77), (.34,.23,.20),'pink')
        ball('Royal nose', (0,-.74,1.88), (.16,.095,.10),'ink')
        rod('Royal sneer', (-.26,-.65,1.65), (.27,-.65,1.67), .038,'ink')
        fang=cone('Royal fang', (-.20,-.69,1.58), (.065,.045,.13),'cream'); fang.rotation_euler.x=math.pi
        band=ring('Crooked crown band', (0,.02,2.47), .49,.10,'gold'); band.rotation_euler.y=-.14
        for i in range(5):
            a=i*math.tau/5
            x=.46*math.cos(a)
            cone('Tall crown point', (x,.02+.40*math.sin(a),2.72+x*.16), (.14,.12,.30),'gold')
        ball('Crown ruby', (0,-.47,2.50), (.13,.045,.14),'red')
        ball('Royal medallion', (0,-.59,1.35), (.18,.055,.20),'gold')

    elif k == 'junkyard_dog':
        box('Bulldog brick torso', (0,.11,.93), (.82,.44,.54),'junkyard_dog')
        ball('Cream chest', (0,-.32,.81), (.49,.12,.42),'cream')
        for s in [-1,1]:
            ball('Massive shoulder', (s*.78,.0,1.12), (.34,.36,.43),'junkyard_dog')
            box('Forepaw', (s*.85,-.28,.47), (.27,.29,.23),'brown')
            box('Hind paw', (s*.48,.04,.17), (.28,.34,.16),'junkyard_dog')
            for i in [-1,0,1]:
                ball('Toe nail', (s*.85+i*.12,-.56,.43), (.045,.06,.07),'cream')
        box('Square bulldog head', (0,-.12,1.75), (.65,.43,.43),'junkyard_dog')
        for s in [-1,1]:
            ear=ball('Flopped ear', (s*.63,.01,2.05), (.23,.23,.31),'brown'); ear.rotation_euler.y=s*.65
        pair(-.52,1.95,.29,.19,.16,.9)
        for s in [-1,1]:
            ball('Heavy cream jowl', (s*.30,-.58,1.60), (.35,.29,.28),'cream')
        box('Underbite jaw', (0,-.48,1.30), (.43,.25,.15),'brown')
        ball('Broad nose', (0,-.89,1.79), (.26,.13,.15),'ink')
        for s in [-1,1]:
            cone('Upward underbite tusk', (s*.29,-.70,1.48), (.09,.07,.20),'cream')
        tongue=ball('Floppy tongue', (.07,-.77,1.30), (.14,.08,.26),'pink'); tongue.rotation_euler.y=.25
        ring('Red spiked collar', (0,.01,1.37), .65,.14,'red')
        for i in range(7):
            a=i*math.tau/7
            cone('Collar spike', (.67*math.cos(a),.53*math.sin(a),1.48), (.10,.10,.23),'cream')
        rod('Stubby tail', (0,.48,.91), (.18,.86,1.04), .12,'brown')

    elif k == 'barn_owl':
        cone('Academic gown', (0,.10,1.11), (.67,.43,.96),'teal')
        ball('Ivory hood', (0,-.015,2.03), (.63,.40,.60),'barn_owl')
        # Two lobes and a tapered chin form a true heart-shaped face.
        for s in [-1,1]:
            ball('Heart face lobe', (s*.25,-.37,2.12), (.32,.13,.38),'cream')
        chin=cone('Heart face chin', (0,-.37,1.80), (.43,.12,.34),'cream'); chin.rotation_euler.x=math.pi
        pair(-.51,2.12,.25,.16,.23,-.4)
        beak=cone('Long ivory owl beak', (0,-.63,1.81), (.12,.10,.24),'gold'); beak.rotation_euler.x=math.pi*.86
        for s in [-1,1]:
            wing=ball('Swept academic wing', (s*.78,.06,1.30), (.56,.24,.26),'navy'); wing.rotation_euler.y=s*-.56
            for i in range(4):
                feather=ball('Long finger feather', (s*(.65+i*.17),.04+i*.07,1.03-i*.09), (.17,.19,.40-i*.035),'navy')
                feather.rotation_euler.y=s*.32
            rod('Teal wing flash', (s*.43,-.18,1.43), (s*1.17,-.12,1.06), .07,'teal')
            rod('Gold stole', (s*.22,-.31,1.57), (s*.30,-.30,.64), .075,'gold')
            ball('Black talon', (s*.29,-.20,.17), (.19,.27,.12),'ink')
        cap=box('Huge mortarboard', (0,.0,2.62), (.76,.53,.07),'ink'); cap.rotation_euler.y=-.09
        box('Mortarboard base', (0,.0,2.49), (.39,.30,.11),'ink')
        rod('Gold tassel cord', (.62,-.02,2.68), (.75,-.09,2.14), .035,'gold')
        cone('Gold tassel', (.75,-.09,2.05), (.09,.07,.16),'gold')
