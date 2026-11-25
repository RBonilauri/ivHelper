# ML Kit découvre ses composants par réflexion : il lit dans le manifeste les
# noms des « registrars » (MlKitComponentDiscoveryService) et les instancie
# avec leur constructeur sans argument. En mode complet, R8 retire ce
# constructeur (jamais appelé dans le code) : ML Kit démarre alors sans
# composants et TextRecognition.getClient plante sur une référence nulle.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
-keep interface com.google.firebase.components.ComponentRegistrar
