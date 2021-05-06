import java.io.*;  
import java.util.*;

public class dec_to_ascii{
    public static void main(String[] args) throws IOException{
        String[] files = {"t04", "t06", "t07", "t08", "t09",
                             "t10", "t11", "t12", "t13",
                              "t14", "t16", "t17", "t18", 
                              "t19","t20", "t21", "t22",
                              "t23", "t24"};
        for (int i = 0; i < files.length; i++){
            String curr_file = "testing/" + files[i] + ".ok";
            Scanner sc = new Scanner(new File(curr_file));
            String output = "";
            while (sc.hasNextInt()){
                char c = (char)(sc.nextInt());
                output += "" + c;
            }

            String out_file = "testing/" + files[i] + ".ok";
            PrintWriter out = new PrintWriter(new FileWriter(new File(out_file)));
            out.println(output);

        }
    }
}