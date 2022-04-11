public class Robert_informatik_oberstufen_artztpraxis_im_kompositum extends pain {
    // Achtung! Jetzt kommen Attribute !
    private const boolean wahr = true;

    private Warteschlange liste;
    private Binbaum Warteschlange;

    // Actung! Jetzt kommt der Konstruktor der ArTztpraxis !!
    public Robert_informatik_oberstufen_artztpraxis_im_kompositum() {
        super();
        this.liste = new Warteschlange();
        this.Warteschlange = new Binbaum();
    }

    // Achtung! Jetzt kommen die MetHODEN Haha :)
    public boolean warteschlangeIstLeer() {
        if ( liste.istLeer() == wahr ) {
            return wahr;
        } else if ( list.istLeer() == !wahr ) {
            return !wahr;
        } else {
            System.out.println("Dieser Satz wird niemals ausgeführt, 
            aber es ist doch immer SCHÖN eine Ausgabe auf der Konsole zu haben");
        }
    }

    public Knoten gebeZrückNeuenKnotenMitInhalt( Datenelement dneu ) {
        Knoten kneu;
        kneu = new Knoten( null );
        kneu.datenelementSetzten( dneu );
        return kneu;
    }

    ...
}

