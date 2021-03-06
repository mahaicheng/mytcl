package edu.bonn.cs.iv.bonnmotion.apps;

import java.io.*;

import edu.bonn.cs.iv.bonnmotion.*;

/** Application that creates a movement file for Glomosim (2.0.3) and Qualnet (3.5.1). */

public class GlomoFile extends App {

	protected String name = null;
	protected boolean qualnet = false;

	public GlomoFile(String[] args) {
		go( args );
	}

	public void go( String[] args ) {
		parse(args);

		Scenario s = null;
		if ( name == null ) {
			printHelp();
			System.exit(0);
		}
		
		try {
			s = new Scenario(name);
		} catch (Exception e) {
			App.exceptionHandler( "Error reading file", e);
		}

		MobileNode[] node = s.getNode();
		
		PrintWriter placements = openPrintWriter(name + ".glomo_nodes");
		PrintWriter movements = openPrintWriter(name + ".glomo_mobility");

		for (int i = 0; i < node.length; i++) {
			int idx = qualnet ? i + 1 : i;
			String[] m = node[i].movementStringGlomo("" + idx);
			for (int j = 0; j < m.length; j++)
				movements.println(m[j]);

			String m2 = node[i].placementStringGlomo("" + idx);
			placements.println(m2);
		}
		movements.close();
		placements.close();
	}

	protected boolean parseArg(char key, String val) {
		switch (key) {
			case 'f':
				name = val;
				return true;
			case 'q':
				qualnet = true;
				return true;
			default:
				return super.parseArg(key, val);
		}
	}

	public static void printHelp() {
		System.out.println();
		App.printHelp();
		System.out.println("GlomoFile:");
		System.out.println("\t-f <filename>");
		System.out.println("\t-q [ QualNet mode: node IDs start at index 1 ]\n");
	}

	public static void main(String[] args) throws FileNotFoundException, IOException {
		new GlomoFile(args);
	}
}
