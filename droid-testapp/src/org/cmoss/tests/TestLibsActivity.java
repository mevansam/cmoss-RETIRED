package org.cmoss.tests;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

public class TestLibsActivity extends Activity 
{
    static 
    {
        System.loadLibrary("log");
        System.loadLibrary("cmoss-tests");
    }
    
    private TextView tv1;
    
    @Override
    public void onCreate(Bundle savedInstanceState) 
    {
        super.onCreate(savedInstanceState);
        super.setContentView(R.layout.main);
        
        initialize(this.getCacheDir().getAbsolutePath() + "/certs");
        
        this.tv1 = (TextView) findViewById(R.id.text1);
    }
    
    @Override
    public void onStart()
    {
    	super.onStart();
    	
        String result = curlTest();
        tv1.setText(result);
    }
    
    @Override
    public void onDestroy()
    {
    	super.onDestroy();
        shutdown();
    }
    
    public native void initialize(String path);
    public native void shutdown();
    
    public native String curlTest();
}
